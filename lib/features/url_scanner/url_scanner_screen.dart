import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';

class UrlScannerScreen extends StatefulWidget {
  const UrlScannerScreen({super.key});

  @override
  State<UrlScannerScreen> createState() => _UrlScannerScreenState();
}

class _UrlScannerScreenState extends State<UrlScannerScreen> {
  final _controller = TextEditingController();
  _ScanState _state = _ScanState.idle;
  UrlResult? _result;
  final _dio = Dio();

  @override
  void dispose() {
    _controller.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _scan() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    String url = raw;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() {
      _state = _ScanState.scanning;
      _result = null;
    });

    try {
      final result = await _analyzeUrl(url);
      setState(() {
        _state = _ScanState.done;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _state = _ScanState.error;
        _result = UrlResult.error(url);
      });
    }
  }

  Future<UrlResult> _analyzeUrl(String url) async {
    final uri = Uri.parse(url);
    final domain = uri.host.toLowerCase();
    final checks = <String, bool>{};
    final warnings = <String>[];
    final positives = <String>[];
    int riskScore = 0;

    // --- Check 1: Known dangerous patterns ---
    final scamKeywords = [
      'prize', 'winner', 'free-gift', 'claim-now', 'lucky', 'jackpot',
      'verify-account', 'update-kyc', 'suspended', 'blocked', 'urgent',
      'paytm-kyc', 'sbi-update', 'hdfc-verify', 'aadhaar-link',
      'g00gle', 'faceb00k', 'amaz0n', 'paypa1', 'netfl1x',
      'bit.ly', 'tinyurl', 'goo.gl', 't.co',
    ];
    final hasScamKeyword = scamKeywords.any((k) => url.toLowerCase().contains(k));
    if (hasScamKeyword) {
      riskScore += 35;
      warnings.add('URL mein suspicious keywords hain');
    }
    checks['Suspicious Keywords'] = !hasScamKeyword;

    // --- Check 2: Domain age heuristics (newly registered-like TLDs) ---
    final suspiciousTlds = ['.xyz', '.top', '.click', '.tk', '.ml', '.ga', '.cf', '.gq', '.work', '.loan', '.win'];
    final hasSuspiciousTld = suspiciousTlds.any((tld) => domain.endsWith(tld));
    if (hasSuspiciousTld) {
      riskScore += 25;
      warnings.add('Ye domain extension (${uri.host.split('.').last}) scammers mein popular hai');
    }
    checks['Safe Domain Extension'] = !hasSuspiciousTld;

    // --- Check 3: HTTPS check ---
    final hasHttps = url.startsWith('https://');
    if (!hasHttps) {
      riskScore += 20;
      warnings.add('Ye site HTTPS use nahi kar rahi — data safe nahi hai');
    } else {
      positives.add('HTTPS encryption hai ✅');
    }
    checks['HTTPS Secure'] = hasHttps;

    // --- Check 4: IP address as URL ---
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    final isIp = ipRegex.hasMatch(domain);
    if (isIp) {
      riskScore += 30;
      warnings.add('URL mein domain nahi, IP address hai — bahut suspicious');
    }
    checks['Uses Domain (not IP)'] = !isIp;

    // --- Check 5: Too many subdomains ---
    final subdomainCount = domain.split('.').length - 2;
    if (subdomainCount > 2) {
      riskScore += 15;
      warnings.add('Bahut zyada subdomains — domain chhupane ki koshish');
    }
    checks['Clean Domain Structure'] = subdomainCount <= 2;

    // --- Check 6: Known safe domains ---
    final safeDomains = [
      'google.com', 'youtube.com', 'facebook.com', 'instagram.com',
      'sbi.co.in', 'hdfcbank.com', 'icicibank.com', 'axisbank.com',
      'amazon.in', 'amazon.com', 'flipkart.com', 'paytm.com',
      'incometax.gov.in', 'uidai.gov.in', 'npci.org.in', 'rbi.org.in',
      'irctc.co.in', 'nic.in', 'gov.in', 'india.gov.in',
    ];
    final isSafeDomain = safeDomains.any((s) => domain == s || domain.endsWith('.$s'));
    if (isSafeDomain) {
      riskScore = 0;
      positives.add('Ye ek verified safe website hai ✅');
      positives.add('Government ya major company ka domain ✅');
    }
    checks['Verified Safe Domain'] = isSafeDomain;

    // --- Check 7: URLhaus API (free, no key needed) ---
    bool urlhausClean = true;
    try {
      final response = await _dio.post(
        'https://urlhaus-api.abuse.ch/v1/url/',
        data: FormData.fromMap({'url': url}),
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.data['query_status'] == 'is_listed') {
        urlhausClean = false;
        riskScore += 50;
        warnings.add('URLhaus database mein listed — confirmed malware/phishing');
      } else {
        positives.add('Malware database mein nahi mila ✅');
      }
    } catch (_) {
      // API unreachable — skip
    }
    checks['URLhaus Database Check'] = urlhausClean;

    // --- Final verdict ---
    final verdict = isSafeDomain
        ? UrlVerdict.safe
        : riskScore >= 50
            ? UrlVerdict.dangerous
            : riskScore >= 25
                ? UrlVerdict.caution
                : UrlVerdict.safe;

    if (riskScore < 25 && !isSafeDomain) {
      positives.add('Koi bada red flag nahi mila');
    }

    return UrlResult(
      url: url,
      domain: domain,
      riskScore: riskScore.clamp(0, 100),
      verdict: verdict,
      checks: checks,
      warnings: warnings,
      positives: positives,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL / Website Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌐', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 8),
                  Text(
                    'Website Safe Hai Ya Nahi?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Koi bhi link paste karo — 2 second mein pata chalega',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 24),

            // Input field
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'www.example.com ya https://... paste karo',
                  prefixIcon: Icon(Icons.link, color: cs.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _state = _ScanState.idle;
                              _result = null;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _scan(),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Scan button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _state == _ScanState.scanning ? null : _scan,
                icon: _state == _ScanState.scanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.security_outlined),
                label: Text(
                  _state == _ScanState.scanning ? 'Scan ho raha hai...' : '🔍 Scan Karo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Result
            if (_result != null) _buildResult(_result!, cs),

            // Tips when idle
            if (_state == _ScanState.idle) _buildTips(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(UrlResult result, ColorScheme cs) {
    final verdictColor = result.verdict == UrlVerdict.safe
        ? const Color(0xFF2E7D32)
        : result.verdict == UrlVerdict.dangerous
            ? const Color(0xFFD32F2F)
            : const Color(0xFFF57F17);

    final verdictBg = result.verdict == UrlVerdict.safe
        ? const Color(0xFFE8F5E9)
        : result.verdict == UrlVerdict.dangerous
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E1);

    final verdictText = result.verdict == UrlVerdict.safe
        ? 'SAFE HAI ✅'
        : result.verdict == UrlVerdict.dangerous
            ? 'DANGEROUS! 🔴'
            : 'SAVDHAN RHO ⚠️';

    final verdictMsg = result.verdict == UrlVerdict.safe
        ? 'Ye website safe lagti hai. Phir bhi personal info share karne se pehle soch lein.'
        : result.verdict == UrlVerdict.dangerous
            ? 'Ye website BILKUL SAFE NAHI hai! Kholo mat — apni koi bhi jankari mat do.'
            : 'Ye website suspicious hai. Dhyan se proceed karo.';

    return Column(
      children: [
        // Main verdict card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: verdictBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: verdictColor.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: verdictColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdictText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.domain,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(verdictMsg,
                        style: TextStyle(fontSize: 15, color: verdictColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // Risk score bar
                    Row(
                      children: [
                        Text('Risk Score: ${result.riskScore}/100',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: result.riskScore / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(verdictColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: 16),

        // Checks list
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Security Checks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...result.checks.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: e.value
                                ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                : const Color(0xFFD32F2F).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            e.value ? Icons.check : Icons.close,
                            size: 16,
                            color: e.value ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e.key, style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        // Warnings
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ Problems Mili:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFD32F2F))),
                const SizedBox(height: 8),
                ...result.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFD32F2F))),
                          Expanded(child: Text(w, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    )),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),
        ],

        // Positives
        if (result.positives.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Achhi Baatein:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),
                const SizedBox(height: 8),
                ...result.positives.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFF2E7D32))),
                          Expanded(child: Text(p, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    )),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTips(ColorScheme cs) {
    final tips = [
      ('🔗', 'Kisi ne link bheja hai?', 'Pehle yahan check karo, phir kholo'),
      ('💰', 'Prize/Lottery ka link?', '99% scam hote hain — check zaroor karo'),
      ('🏦', 'Bank ka link?', 'Bank kabhi link se login nahi karata'),
      ('🛒', 'Shopping deal mili?', 'Fake sites original jaise dikhti hain'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📚 Kab Use Karein?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...tips.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Text(e.value.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.$2,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(e.value.$3,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80))),
      ],
    );
  }
}

enum _ScanState { idle, scanning, done, error }

enum UrlVerdict { safe, caution, dangerous }

class UrlResult {
  final String url;
  final String domain;
  final int riskScore;
  final UrlVerdict verdict;
  final Map<String, bool> checks;
  final List<String> warnings;
  final List<String> positives;

  UrlResult({
    required this.url,
    required this.domain,
    required this.riskScore,
    required this.verdict,
    required this.checks,
    required this.warnings,
    required this.positives,
  });

  factory UrlResult.error(String url) => UrlResult(
        url: url,
        domain: Uri.tryParse(url)?.host ?? url,
        riskScore: 0,
        verdict: UrlVerdict.caution,
        checks: {'Network Check': false},
        warnings: ['Check karne mein problem aayi — internet connection dekho'],
        positives: [],
      );
}
