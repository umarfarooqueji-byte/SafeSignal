import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiScannerScreen extends StatefulWidget {
  const WifiScannerScreen({super.key});

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen> {
  _WifiState _state = _WifiState.idle;
  WifiResult? _result;
  final _networkInfo = NetworkInfo();

  Future<void> _scan() async {
    setState(() {
      _state = _WifiState.scanning;
      _result = null;
    });

    await Future.delayed(const Duration(seconds: 2)); // simulate checks

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);

      if (!isWifi) {
        setState(() {
          _state = _WifiState.done;
          _result = WifiResult.noWifi();
        });
        return;
      }

      // Get network info
      String? ssid;
      String? bssid;
      String? gateway;
      String? ip;

      try {
        ssid = await _networkInfo.getWifiName();
        bssid = await _networkInfo.getWifiBSSID();
        gateway = await _networkInfo.getWifiGatewayIP();
        // subnet check skipped (unused)
        ip = await _networkInfo.getWifiIP();
      } catch (_) {
        ssid = 'Unknown Network';
      }

      // Clean SSID (remove quotes)
      ssid = ssid?.replaceAll('"', '') ?? 'Unknown';

      final checks = <WifiCheck>[];
      int riskScore = 0;

      // Check 1: Public/open network indicators
      final publicKeywords = ['free', 'public', 'open', 'guest', 'cafe', 'hotel',
          'airport', 'station', 'mall', 'restaurant', 'starbucks'];
      final isPublicLike = publicKeywords.any((k) => ssid!.toLowerCase().contains(k));
      if (isPublicLike) {
        riskScore += 30;
        checks.add(WifiCheck(
          name: 'Network Type',
          status: CheckStatus.warning,
          detail: 'Public network lagta hai — banking mat karo',
        ));
      } else {
        checks.add(WifiCheck(
          name: 'Network Type',
          status: CheckStatus.safe,
          detail: 'Private network hai',
        ));
      }

      // Check 2: Default router names (often not secured)
      final defaultRouterNames = ['dlink', 'd-link', 'netgear', 'tp-link', 'tplink',
          'linksys', 'asus', 'belkin', 'default', 'router', 'wifi', 'wireless'];
      final isDefault = defaultRouterNames.any((k) => ssid!.toLowerCase().contains(k));
      if (isDefault) {
        riskScore += 20;
        checks.add(WifiCheck(
          name: 'Router Configuration',
          status: CheckStatus.warning,
          detail: 'Default naam se lagta hai router properly configured nahi — password change karein',
        ));
      } else {
        checks.add(WifiCheck(
          name: 'Router Configuration',
          status: CheckStatus.safe,
          detail: 'Custom network naam — likely configured hai',
        ));
      }

      // Check 3: Suspicious/clone network names
      final suspiciousKeywords = ['hack', 'evil', 'spy', 'sniff', 'mitm', 'fake'];
      final isSuspiciousName = suspiciousKeywords.any((k) => ssid!.toLowerCase().contains(k));
      if (isSuspiciousName) {
        riskScore += 50;
        checks.add(WifiCheck(
          name: 'Network Name Safety',
          status: CheckStatus.danger,
          detail: 'Network ka naam suspicious hai!',
        ));
      } else {
        checks.add(WifiCheck(
          name: 'Network Name Safety',
          status: CheckStatus.safe,
          detail: 'Network naam suspicious nahi',
        ));
      }

      // Check 4: IP range check (common home ranges are fine)
      if (ip != null && ip.isNotEmpty) {
        final isPrivateIp = ip.startsWith('192.168.') ||
            ip.startsWith('10.') ||
            ip.startsWith('172.');
        if (!isPrivateIp) {
          riskScore += 25;
          checks.add(WifiCheck(
            name: 'IP Address Range',
            status: CheckStatus.warning,
            detail: 'Unusual IP address ($ip) — suspicious',
          ));
        } else {
          checks.add(WifiCheck(
            name: 'IP Address Range',
            status: CheckStatus.safe,
            detail: 'Normal private IP ($ip)',
          ));
        }
      }

      // Check 5: Gateway check
      if (gateway != null && gateway.isNotEmpty) {
        checks.add(WifiCheck(
          name: 'Gateway Detected',
          status: CheckStatus.safe,
          detail: 'Router gateway: $gateway',
        ));
      } else {
        riskScore += 10;
        checks.add(WifiCheck(
          name: 'Gateway Detected',
          status: CheckStatus.warning,
          detail: 'Gateway detect nahi ho saka',
        ));
      }

      // Check 6: VPN recommendation for public
      if (isPublicLike) {
        checks.add(WifiCheck(
          name: 'VPN Recommendation',
          status: CheckStatus.warning,
          detail: 'Public WiFi pe VPN use karo — zyada safe rahoge',
        ));
      }

      final verdict = riskScore >= 50
          ? WifiVerdict.dangerous
          : riskScore >= 20
              ? WifiVerdict.caution
              : WifiVerdict.safe;

      final tips = <String>[
        if (isPublicLike) 'Public WiFi pe banking/UPI BILKUL mat karo',
        if (isPublicLike) 'VPN use karo agar public WiFi use karna hai',
        if (isDefault) 'Apne router ka naam aur password badlo',
        'WiFi se disconnect karo jab use na ho',
        'Ghar ka WiFi WPA3 ya WPA2 pe set karo',
        'Unknown networks se connect mat hona',
      ];

      setState(() {
        _state = _WifiState.done;
        _result = WifiResult(
          ssid: ssid ?? 'Unknown',
          bssid: bssid ?? 'N/A',
          ip: ip ?? 'N/A',
          gateway: gateway ?? 'N/A',
          riskScore: riskScore.clamp(0, 100),
          verdict: verdict,
          checks: checks,
          tips: tips,
          isConnected: true,
        );
      });
    } catch (e) {
      setState(() {
        _state = _WifiState.done;
        _result = WifiResult.error();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Security Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📶', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 8),
                  Text(
                    'WiFi Safe Hai Ya Nahi?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Apne current network ki security check karo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Scan button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _state == _WifiState.scanning ? null : _scan,
                icon: _state == _WifiState.scanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wifi_find_outlined),
                label: Text(
                  _state == _WifiState.scanning
                      ? 'Network scan ho raha hai...'
                      : '📶 WiFi Scan Karo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            if (_result != null) _buildResult(_result!, cs),
            if (_state == _WifiState.idle) _buildInfoCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(WifiResult result, ColorScheme cs) {
    if (!result.isConnected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Text('📡', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('WiFi Connected Nahi Hai',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Pehle WiFi se connect karo, phir scan karo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ).animate().fadeIn();
    }

    final verdictColor = result.verdict == WifiVerdict.safe
        ? const Color(0xFF2E7D32)
        : result.verdict == WifiVerdict.dangerous
            ? const Color(0xFFD32F2F)
            : const Color(0xFFF57F17);

    final verdictBg = result.verdict == WifiVerdict.safe
        ? const Color(0xFFE8F5E9)
        : result.verdict == WifiVerdict.dangerous
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E1);

    final verdictText = result.verdict == WifiVerdict.safe
        ? 'SAFE NETWORK ✅'
        : result.verdict == WifiVerdict.dangerous
            ? 'UNSAFE NETWORK! 🔴'
            : 'SAVDHAN RAHO ⚠️';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main verdict
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
                child: Row(
                  children: [
                    const Icon(Icons.wifi, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(verdictText,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(result.ssid,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Risk Score:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${result.riskScore}/100',
                            style: TextStyle(color: verdictColor, fontWeight: FontWeight.bold)),
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

        // Network Details
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
              const Text('Network Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _detailRow('📶 Network (SSID)', result.ssid),
              _detailRow('📍 IP Address', result.ip),
              _detailRow('🔀 Gateway', result.gateway),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Security Checks
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
              ...result.checks.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: e.value.status == CheckStatus.safe
                                ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                : e.value.status == CheckStatus.danger
                                    ? const Color(0xFFD32F2F).withValues(alpha: 0.1)
                                    : const Color(0xFFF57F17).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            e.value.status == CheckStatus.safe
                                ? Icons.check
                                : e.value.status == CheckStatus.danger
                                    ? Icons.close
                                    : Icons.warning_amber_outlined,
                            size: 16,
                            color: e.value.status == CheckStatus.safe
                                ? const Color(0xFF2E7D32)
                                : e.value.status == CheckStatus.danger
                                    ? const Color(0xFFD32F2F)
                                    : const Color(0xFFF57F17),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(e.value.detail,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80))),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms),

        // Tips
        if (result.tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF57F17).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 Safety Tips:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFE65100))),
                const SizedBox(height: 8),
                ...result.tips.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFE65100))),
                          Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    final items = [
      ('⚠️', 'Public WiFi Danger', 'Free WiFi pe hackers aapka data chura sakte hain'),
      ('🏠', 'Ghar ka WiFi', 'WPA2/WPA3 encryption use karein'),
      ('🔐', 'Password', 'Simple password kabhi mat rakhein'),
      ('📵', 'Auto-connect', 'Unknown networks se auto-connect band karo'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📚 WiFi ke Baare Mein Jaano',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.1)),
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

enum _WifiState { idle, scanning, done }
enum WifiVerdict { safe, caution, dangerous }
enum CheckStatus { safe, warning, danger }

class WifiCheck {
  final String name;
  final CheckStatus status;
  final String detail;
  const WifiCheck({required this.name, required this.status, required this.detail});
}

class WifiResult {
  final String ssid;
  final String bssid;
  final String ip;
  final String gateway;
  final int riskScore;
  final WifiVerdict verdict;
  final List<WifiCheck> checks;
  final List<String> tips;
  final bool isConnected;

  const WifiResult({
    required this.ssid,
    required this.bssid,
    required this.ip,
    required this.gateway,
    required this.riskScore,
    required this.verdict,
    required this.checks,
    required this.tips,
    required this.isConnected,
  });

  factory WifiResult.noWifi() => const WifiResult(
        ssid: '', bssid: '', ip: '', gateway: '',
        riskScore: 0, verdict: WifiVerdict.safe,
        checks: [], tips: [], isConnected: false,
      );

  factory WifiResult.error() => const WifiResult(
        ssid: 'Error', bssid: '', ip: '', gateway: '',
        riskScore: 0, verdict: WifiVerdict.caution,
        checks: [WifiCheck(name: 'Scan', status: CheckStatus.warning, detail: 'Permission chahiye — Settings se allow karo')],
        tips: ['Location permission do — WiFi name detect hoga'],
        isConnected: true,
      );
}
