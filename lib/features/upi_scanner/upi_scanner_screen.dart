import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/crowd_intel_service.dart';

class UpiScannerScreen extends StatefulWidget {
  const UpiScannerScreen({super.key});

  @override
  State<UpiScannerScreen> createState() => _UpiScannerScreenState();
}

class _UpiScannerScreenState extends State<UpiScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController? _scanController;
  _UpiScanResult? _scanResult;
  bool _isScanning = true;
  bool _isAnalyzing = false;
  bool _torchOn = false;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _scanController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Init crowd intel
    CrowdIntelService().init();
  }

  @override
  void dispose() {
    _scanController?.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onDetected(BarcodeCapture capture) async {
    if (!_isScanning || _isAnalyzing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    setState(() {
      _isScanning = false;
      _isAnalyzing = true;
    });

    HapticFeedback.mediumImpact();
    await _scanController?.stop();

    // Analyze
    final result = await _analyzeQrCode(raw);

    setState(() {
      _scanResult = result;
      _isAnalyzing = false;
    });
  }

  Future<_UpiScanResult> _analyzeQrCode(String raw) async {
    final lower = raw.toLowerCase();

    // ─── UPI Payment Intent ───────────────────────────────────────────────
    if (lower.startsWith('upi://')) {
      return _analyzeUpiIntent(raw);
    }

    // ─── URL QR Code ─────────────────────────────────────────────────────
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return _analyzeUrlQr(raw);
    }

    // ─── Plain text / unknown ─────────────────────────────────────────────
    return _UpiScanResult(
      type: QrType.unknown,
      rawValue: raw,
      displayValue: raw,
      verdict: 'SAFE',
      riskScore: 5,
      isPayment: false,
      paymentDirection: null,
      warnings: [],
      summary: 'This QR code contains plain text — no payment link detected.',
    );
  }

  _UpiScanResult _analyzeUpiIntent(String raw) {
    final uri = Uri.tryParse(raw);
    final params = uri?.queryParameters ?? {};

    final vpa = params['pa'] ?? params['vpa'] ?? '';
    final name = params['pn'] ?? 'Unknown';
    final amountStr = params['am'] ?? '';
    final transactionRef = params['tr'] ?? '';
    final remarks = params['tn'] ?? '';

    double? amount;
    try {
      amount = double.tryParse(amountStr);
    } catch (_) {}

    final warnings = <String>[];
    var riskScore = 0;

    // ─── Direction detection ─────────────────────────────────────────────
    // Cashback scam: negative amount = they receive, you send
    String direction = 'SEND';
    if (amount != null && amount < 0) {
      direction = 'RECEIVE (TRAP!)';
      riskScore += 40;
      warnings.add('⚠️ Negative amount detected! You will SEND money, not receive — this is a cashback scam!');
    }

    // "collect request" hidden in remarks
    if (remarks.toLowerCase().contains('collect') ||
        transactionRef.toLowerCase().contains('collect')) {
      direction = 'RECEIVE (TRAP!)';
      riskScore += 30;
      warnings.add('This is a "collect request" — accepting it means you PAY money');
    }

    // ─── VPA risk analysis ────────────────────────────────────────────────
    final vpaDomain = vpa.split('@').lastOrNull ?? '';

    // Suspicious VPA domain patterns
    const suspiciousDomains = ['ybl', 'axisb', 'idfcfirst', 'freecharge'];
    const personalDomains = ['oksbi', 'okaxis', 'okhdfc', 'okhdfcbank', 'paytm', 'upi'];

    final isPersonalAccount = personalDomains.contains(vpaDomain);
    final isSuspiciousVpaDomain = suspiciousDomains.any((d) => vpaDomain.contains(d));

    if (isSuspiciousVpaDomain) {
      riskScore += 10;
    }

    if (isPersonalAccount && amount != null && amount > 5000) {
      riskScore += 20;
      warnings.add('You are paying a large amount to a PERSONAL account, not a business — verify carefully');
    }

    // Crowd Intel check for this VPA
    final crowdKnown = CrowdIntelService().isKnownThreat(vpa);
    if (crowdKnown) {
      riskScore += 50;
      warnings.add('🚨 This UPI ID has been REPORTED by other users as a scammer!');
    }

    // ─── Name spoofing check ──────────────────────────────────────────────
    final nameLower = name.toLowerCase();
    const trustedNames = ['sbi', 'hdfc', 'icici', 'axis', 'paytm', 'amazon', 'flipkart'];
    final nameMatchesTrusted = trustedNames.any((t) => nameLower.contains(t));
    if (nameMatchesTrusted && isPersonalAccount) {
      riskScore += 35;
      warnings.add('Name "$name" sounds like a bank/brand but VPA is a personal account — possible impersonation!');
    }

    riskScore = riskScore.clamp(0, 100);

    String verdict;
    if (riskScore >= 60) {
      verdict = 'SCAM';
    } else if (riskScore >= 30) {
      verdict = 'SUSPICIOUS';
    } else {
      verdict = 'SAFE';
    }

    String summary;
    if (verdict == 'SCAM') {
      summary = 'HIGH RISK! Do NOT proceed with this payment. Multiple fraud indicators found.';
    } else if (verdict == 'SUSPICIOUS') {
      summary = 'Verify carefully before paying. Some unusual patterns detected.';
    } else {
      summary = 'Payment looks legitimate. Always verify recipient name before confirming.';
    }

    return _UpiScanResult(
      type: QrType.upi,
      rawValue: raw,
      displayValue: vpa,
      verdict: verdict,
      riskScore: riskScore,
      isPayment: true,
      paymentDirection: direction,
      vpa: vpa,
      merchantName: name,
      amount: amount,
      warnings: warnings,
      summary: summary,
    );
  }

  _UpiScanResult _analyzeUrlQr(String raw) {
    final uri = Uri.tryParse(raw);
    final host = uri?.host ?? '';
    final warnings = <String>[];
    var riskScore = 0;

    const suspiciousPatterns = [
      '-secure', '-verify', '-login', '-bank', '-kyc', '-update',
      'sbi-', 'hdfc-', 'paytm-', 'bit.ly', 'tinyurl',
    ];

    for (final p in suspiciousPatterns) {
      if (host.contains(p)) {
        riskScore += 25;
        warnings.add('Domain contains suspicious pattern "$p" — possible phishing site');
        break;
      }
    }

    if (uri?.scheme == 'http') {
      riskScore += 15;
      warnings.add('Non-HTTPS link — connection is not encrypted');
    }

    final crowdKnown = CrowdIntelService().isKnownThreat(raw);
    if (crowdKnown) {
      riskScore += 50;
      warnings.add('🚨 This link has been reported by other users as malicious!');
    }

    riskScore = riskScore.clamp(0, 100);
    final verdict = riskScore >= 60 ? 'SCAM' : (riskScore >= 30 ? 'SUSPICIOUS' : 'SAFE');

    return _UpiScanResult(
      type: QrType.url,
      rawValue: raw,
      displayValue: host,
      verdict: verdict,
      riskScore: riskScore,
      isPayment: false,
      paymentDirection: null,
      warnings: warnings,
      summary: verdict == 'SAFE'
          ? 'URL looks legitimate.'
          : 'This URL may be a phishing link. Do not open it.',
    );
  }

  void _resetScan() {
    setState(() {
      _scanResult = null;
      _isScanning = true;
      _isAnalyzing = false;
    });
    _scanController?.start();
  }

  Future<void> _reportVpa(String vpa) async {
    if (_scanResult == null) return;
    await CrowdIntelService().reportThreat(
      rawValue: vpa,
      type: 'upi',
      verdict: 'SCAM',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reported! This will protect other users.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'UPI & QR Scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_isScanning)
            IconButton(
              icon: Icon(
                _torchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
                color: _torchOn ? Colors.yellow : Colors.white,
              ),
              onPressed: () {
                setState(() => _torchOn = !_torchOn);
                _scanController?.toggleTorch();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _scanResult != null
          ? _buildResultView(_scanResult!)
          : _isAnalyzing
              ? _buildAnalyzingView()
              : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera feed
        MobileScanner(
          controller: _scanController!,
          onDetect: _onDetected,
        ),

        // Scan overlay
        Center(
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              return Container(
                width: 260 + _pulseCtrl.value * 4,
                height: 260 + _pulseCtrl.value * 4,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7 + _pulseCtrl.value * 0.3),
                    width: 2.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    ..._buildCorners(),
                    // Scan line animation
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 16 + _pulseCtrl.value * 220,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF2979FF).withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Instructions
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.qrcode_viewfinder, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Point at UPI QR code to scan',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              const Text(
                'Detects cashback scams, fake merchants & phishing links',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 3.5;
    const color = Color(0xFF2979FF);
    return [
      Positioned(top: -1, left: -1, child: _corner(size, thickness, color, topLeft: true)),
      Positioned(top: -1, right: -1, child: _corner(size, thickness, color, topRight: true)),
      Positioned(bottom: -1, left: -1, child: _corner(size, thickness, color, bottomLeft: true)),
      Positioned(bottom: -1, right: -1, child: _corner(size, thickness, color, bottomRight: true)),
    ];
  }

  Widget _corner(double size, double thickness, Color color, {
    bool topLeft = false, bool topRight = false,
    bool bottomLeft = false, bool bottomRight = false,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(
        color: color, thickness: thickness,
        topLeft: topLeft, topRight: topRight,
        bottomLeft: bottomLeft, bottomRight: bottomRight,
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF2979FF),
              strokeWidth: 3,
            ),
          ).animate().scale(duration: 400.ms),
          const SizedBox(height: 24),
          const Text(
            'Analyzing...',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Checking crowd database & fraud patterns',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(_UpiScanResult result) {
    final isScam = result.verdict == 'SCAM';
    final isSuspicious = result.verdict == 'SUSPICIOUS';
    final primaryColor = isScam
        ? const Color(0xFFE53935)
        : isSuspicious
            ? const Color(0xFFFF8F00)
            : const Color(0xFF43A047);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Verdict banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isScam ? '🚨' : (isSuspicious ? '⚠️' : '✅'),
                    style: const TextStyle(fontSize: 48),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 8),
                  Text(
                    isScam ? 'FRAUD DETECTED' : (isSuspicious ? 'SUSPICIOUS' : 'LOOKS SAFE'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Risk score bar
                  Column(
                    children: [
                      Text(
                        'Risk Score: ${result.riskScore}/100',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: result.riskScore / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          color: Colors.white,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: -0.1, duration: 350.ms),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Payment direction card (only for UPI)
                  if (result.isPayment && result.paymentDirection != null) ...[
                    _buildDirectionCard(result, primaryColor),
                    const SizedBox(height: 16),
                  ],

                  // UPI Details card
                  if (result.vpa != null) ...[
                    _buildDetailCard(result),
                    const SizedBox(height: 16),
                  ],

                  // Summary
                  _buildInfoCard(
                    icon: CupertinoIcons.info_circle_fill,
                    title: 'Analysis',
                    body: result.summary,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),

                  // Warnings
                  if (result.warnings.isNotEmpty) ...[
                    ...result.warnings.asMap().entries.map((e) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildWarningCard(e.value, e.key),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          label: 'Scan Again',
                          icon: CupertinoIcons.qrcode_viewfinder,
                          color: const Color(0xFF2979FF),
                          onTap: _resetScan,
                        ),
                      ),
                      if (isScam && result.vpa != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            label: 'Report Scam',
                            icon: CupertinoIcons.flag_fill,
                            color: const Color(0xFFE53935),
                            onTap: () => _reportVpa(result.vpa!),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reports help protect all SafeSignal users',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionCard(_UpiScanResult result, Color color) {
    final isRisky = result.paymentDirection != 'SEND';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRisky
            ? const Color(0xFFE53935).withValues(alpha: 0.08)
            : const Color(0xFF43A047).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRisky
              ? const Color(0xFFE53935).withValues(alpha: 0.3)
              : const Color(0xFF43A047).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRisky ? CupertinoIcons.arrow_right_arrow_left : CupertinoIcons.arrow_up_circle_fill,
            color: isRisky ? const Color(0xFFE53935) : const Color(0xFF43A047),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Direction',
                  style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'You will ${isRisky ? "PAY (not receive!)" : "PAY"} ${result.amount != null ? "₹${result.amount!.abs().toStringAsFixed(0)}" : ""}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isRisky ? const Color(0xFFE53935) : const Color(0xFF0D1117),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildDetailCard(_UpiScanResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _detailRow('UPI ID', result.vpa ?? ''),
          const Divider(height: 20),
          _detailRow('Name', result.merchantName ?? 'Unknown'),
          if (result.amount != null) ...[
            const Divider(height: 20),
            _detailRow('Amount', '₹${result.amount!.abs().toStringAsFixed(2)}'),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.45), fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0D1117))),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13, color: Color(0xFF0D1117), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildWarningCard(String warning, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔴', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(warning, style: const TextStyle(fontSize: 13, color: Color(0xFF0D1117), height: 1.45)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 250 + index * 60));
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────
enum QrType { upi, url, unknown }

class _UpiScanResult {
  final QrType type;
  final String rawValue;
  final String displayValue;
  final String verdict;
  final int riskScore;
  final bool isPayment;
  final String? paymentDirection;
  final String? vpa;
  final String? merchantName;
  final double? amount;
  final List<String> warnings;
  final String summary;

  const _UpiScanResult({
    required this.type,
    required this.rawValue,
    required this.displayValue,
    required this.verdict,
    required this.riskScore,
    required this.isPayment,
    required this.paymentDirection,
    this.vpa,
    this.merchantName,
    this.amount,
    required this.warnings,
    required this.summary,
  });
}

// ─── Corner painter ───────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({
    required this.color,
    required this.thickness,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 20.0;
    if (topLeft) {
      canvas.drawLine(Offset.zero, Offset(len, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, len), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
