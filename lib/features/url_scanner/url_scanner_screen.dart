import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';

import '../../core/constants.dart';

class UrlScannerScreen extends StatefulWidget {
  const UrlScannerScreen({super.key});

  @override
  State<UrlScannerScreen> createState() => _UrlScannerScreenState();
}

enum _ScanState { idle, scanning, done, error }

class _UrlScannerScreenState extends State<UrlScannerScreen> {
  final _controller = TextEditingController();
  _ScanState _state = _ScanState.idle;
  UrlResult? _result;
  String _statusMsg = '';
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  void dispose() {
    _controller.dispose();
    _dio.close();
    super.dispose();
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMsg = msg);
  }

  Future<void> _scan() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    FocusScope.of(context).unfocus();

    String url = raw;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url'; // Default to HTTPS for testing
    }

    setState(() {
      _state = _ScanState.scanning;
      _result = null;
      _statusMsg = 'Initializing deep scan...';
    });

    try {
      final result = await _analyzeUrl(url);

      // Save to Supabase
      try {
        await SupabaseService().saveScanHistory(
          scanType: 'URL',
          target: url,
          status: result.verdict == UrlVerdict.dangerous ? 'DANGER' : (result.verdict == UrlVerdict.caution ? 'WARNING' : 'SAFE'),
          details: {'riskScore': result.riskScore, 'domain': result.domain},
        );
      } catch (e) {
        debugPrint('Supabase save error: $e');
      }

      if (!mounted) return;
      setState(() {
        _state = _ScanState.done;
        _result = result;
        _statusMsg = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _result = UrlResult.error(url);
        _statusMsg = '';
      });
    }
  }

  String _getBaseDomain(String domain) {
    final parts = domain.split('.');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
    }
    return domain;
  }

  // A hardcoded list of major trusted domains for India
  final _allowlist = {
    'google.com', 'youtube.com', 'facebook.com', 'instagram.com', 'whatsapp.com',
    'sbi.co.in', 'hdfcbank.com', 'icicibank.com', 'axisbank.com', 'kotak.com',
    'amazon.in', 'amazon.com', 'flipkart.com', 'myntra.com', 'meesho.com',
    'paytm.com', 'phonepe.com', 'gpay.app',
    'incometax.gov.in', 'uidai.gov.in', 'npci.org.in', 'rbi.org.in', 'onlinesbi.sbi',
    'irctc.co.in', 'nic.in', 'gov.in', 'india.gov.in', 'passportindia.gov.in',
    'bsnl.co.in', 'tatamotors.com', 'reliance.com', 'jio.com',
    'microsoft.com', 'apple.com', 'linkedin.com', 'twitter.com', 'x.com'
  };

  Future<UrlResult> _analyzeUrl(String url) async {
    final uri = Uri.tryParse(url) ?? Uri(host: url);
    final domain = uri.host.toLowerCase().replaceAll('www.', '');
    final baseDomain = _getBaseDomain(domain);
    
    final domainChecks = <DomainCheckItem>[];
    int riskScore = 0; // 0-100
    bool isAllowlisted = false;

    // 1. LOCAL ALLOWLIST CHECK
    _setStatus('Checking local trusted registry...');
    if (_allowlist.contains(baseDomain) || _allowlist.contains(domain) || domain.endsWith('.gov.in') || domain.endsWith('.nic.in')) {
      isAllowlisted = true;
      domainChecks.add(DomainCheckItem('Trusted Registry', true, 'Known safe organization/government domain.'));
    } else {
      domainChecks.add(DomainCheckItem('Trusted Registry', null, 'Not in local allowlist (Neutral).'));
    }

    // Parallel API Futures
    Future<_HttpsResult> httpsFuture = _checkHttps(url, domain);
    Future<_SafeBrowsingResult> safeBrowsingFuture = _checkSafeBrowsing(url);
    Future<_VirusTotalResult> vtFuture = _checkVirusTotal(domain);
    Future<_UrlHausResult> urlHausFuture = _checkUrlHaus(url);
    Future<_DomainAgeResult> ageFuture = _checkDomainAge(domain);

    // Wait for all checks
    final results = await Future.wait([
      httpsFuture,
      safeBrowsingFuture,
      vtFuture,
      urlHausFuture,
      ageFuture,
    ]);

    final https = results[0] as _HttpsResult;
    final sb = results[1] as _SafeBrowsingResult;
    final vt = results[2] as _VirusTotalResult;
    final urlHaus = results[3] as _UrlHausResult;
    final age = results[4] as _DomainAgeResult;

    // 2. HTTPS RESOLUTION CHECK
    if (https.isSecure) {
      domainChecks.add(DomainCheckItem('HTTPS Encryption', true, 'Valid SSL certificate verified.'));
    } else {
      riskScore += 20;
      domainChecks.add(DomainCheckItem('HTTPS Encryption', false, 'Missing or invalid SSL certificate. Unsafe for data.'));
    }

    // 3. GOOGLE SAFE BROWSING
    if (sb.isMalicious) {
      riskScore += 60;
      domainChecks.add(DomainCheckItem('Google Safe Browsing', false, 'Flagged by Google as dangerous (${sb.threatType}).'));
    } else if (sb.apiFailed) {
      domainChecks.add(DomainCheckItem('Google Safe Browsing', null, 'API unavailable or missing key. Could not verify.'));
    } else {
      domainChecks.add(DomainCheckItem('Google Safe Browsing', true, 'Clean. No threats found by Google.'));
    }

    // 4. VIRUSTOTAL
    if (vt.maliciousCount > 0) {
      riskScore += 30;
      domainChecks.add(DomainCheckItem('VirusTotal Engine', false, 'Flagged by ${vt.maliciousCount} security vendors.'));
    } else if (vt.apiFailed) {
      domainChecks.add(DomainCheckItem('VirusTotal Engine', null, 'API unavailable or missing key. Could not verify.'));
    } else {
      domainChecks.add(DomainCheckItem('VirusTotal Engine', true, 'Clean across all major security vendors.'));
    }

    // 5. URLHAUS
    if (urlHaus.isListed) {
      riskScore += 50;
      domainChecks.add(DomainCheckItem('URLhaus Malware DB', false, 'Confirmed malware distribution site.'));
    } else if (urlHaus.apiFailed) {
      domainChecks.add(DomainCheckItem('URLhaus Malware DB', null, 'Service unreachable.'));
    } else {
      domainChecks.add(DomainCheckItem('URLhaus Malware DB', true, 'Not listed in malware databases.'));
    }

    // 6. DOMAIN AGE / WHOIS
    if (age.apiFailed) {
      domainChecks.add(DomainCheckItem('Domain Age (RDAP)', null, 'Could not fetch domain registration data.'));
    } else {
      if (age.daysOld >= 0 && age.daysOld < 30) {
        riskScore += 15;
        domainChecks.add(DomainCheckItem('Domain Age (RDAP)', false, 'Registered very recently (${age.daysOld} days ago). High risk of scam.'));
      } else if (age.daysOld >= 30) {
        domainChecks.add(DomainCheckItem('Domain Age (RDAP)', true, 'Established domain (${age.daysOld} days old).'));
      }
    }

    // 7. IP ADDRESS PATTERN
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipRegex.hasMatch(domain)) {
      riskScore += 25;
      domainChecks.add(DomainCheckItem('Domain Structure', false, 'Using raw IP address instead of domain.'));
    }

    // 8. SCAM KEYWORDS
    final scamKeywords = ['prize', 'winner', 'free', 'lucky', 'jackpot', 'kyc', 'verify', 'urgent'];
    if (scamKeywords.any((k) => url.toLowerCase().contains(k))) {
      riskScore += 10;
      domainChecks.add(DomainCheckItem('URL Pattern', false, 'Suspicious keywords found in URL.'));
    }

    // Cap score at 100
    riskScore = riskScore.clamp(0, 100);

    // If it's a known top-level allowlisted domain, force score to 0 unless live APIs explicitly catch malware (highly unlikely for real google.com, but catches typos)
    if (isAllowlisted && riskScore < 60) {
      riskScore = 0;
    }

    final verdict = isAllowlisted && riskScore == 0
        ? UrlVerdict.safe
        : riskScore >= 51
            ? UrlVerdict.dangerous
            : riskScore >= 21
                ? UrlVerdict.caution
                : UrlVerdict.safe;

    return UrlResult(
      url: url,
      domain: domain,
      riskScore: riskScore,
      verdict: verdict,
      checks: {}, // Deprecated, keeping for model compatibility
      warnings: [], // Handled by domainChecks now
      positives: [], // Handled by domainChecks now
      domainChecks: domainChecks,
      isVerifiedSafe: isAllowlisted,
    );
  }

  // --- Pipeline Implementations ---

  Future<_HttpsResult> _checkHttps(String originalUrl, String domain) async {
    _setStatus('Verifying SSL Certificate...');
    try {
      final checkUrl = 'https://$domain';
      final response = await _dio.get(checkUrl, options: Options(
        validateStatus: (status) => true,
        receiveTimeout: const Duration(seconds: 4),
      ));
      return _HttpsResult(isSecure: response.statusCode != null);
    } catch (_) {
      return _HttpsResult(isSecure: false);
    }
  }

  Future<_SafeBrowsingResult> _checkSafeBrowsing(String url) async {
    _setStatus('Querying Google Safe Browsing...');
    if (AppConstants.googleSafeBrowsingApiKey.isEmpty) { 
      return _SafeBrowsingResult(apiFailed: true);
    }
    try {
      final body = {
        "client": {"clientId": "safesignal", "clientVersion": "1.0.0"},
        "threatInfo": {
          "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
          "platformTypes": ["ANY_PLATFORM"],
          "threatEntryTypes": ["URL"],
          "threatEntries": [{"url": url}]
        }
      };
      final response = await _dio.post(
        'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=${AppConstants.googleSafeBrowsingApiKey}',
        data: jsonEncode(body),
        options: Options(receiveTimeout: const Duration(seconds: 4)),
      );
      if (response.statusCode == 200 && response.data != null && response.data['matches'] != null) {
        final matches = response.data['matches'] as List;
        if (matches.isNotEmpty) {
          return _SafeBrowsingResult(isMalicious: true, threatType: matches[0]['threatType']);
        }
      }
      return _SafeBrowsingResult(isMalicious: false);
    } catch (_) {
      return _SafeBrowsingResult(apiFailed: true);
    }
  }

  Future<_VirusTotalResult> _checkVirusTotal(String domain) async {
    _setStatus('Querying VirusTotal Engines...');
    if (AppConstants.virusTotalApiKey.isEmpty) {
      return _VirusTotalResult(apiFailed: true);
    }
    try {
      final response = await _dio.get(
        'https://www.virustotal.com/api/v3/domains/$domain',
        options: Options(
          headers: {'x-apikey': AppConstants.virusTotalApiKey},
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (response.statusCode == 200) {
        final stats = response.data['data']['attributes']['last_analysis_stats'];
        final malicious = stats['malicious'] as int? ?? 0;
        return _VirusTotalResult(maliciousCount: malicious);
      }
      return _VirusTotalResult(apiFailed: true);
    } catch (_) {
      return _VirusTotalResult(apiFailed: true);
    }
  }

  Future<_UrlHausResult> _checkUrlHaus(String url) async {
    _setStatus('Querying URLhaus Malware DB...');
    try {
      final response = await _dio.post(
        'https://urlhaus-api.abuse.ch/v1/url/',
        data: FormData.fromMap({'url': url}),
        options: Options(receiveTimeout: const Duration(seconds: 4)),
      );
      return _UrlHausResult(isListed: response.data['query_status'] == 'is_listed');
    } catch (_) {
      return _UrlHausResult(apiFailed: true);
    }
  }

  Future<_DomainAgeResult> _checkDomainAge(String domain) async {
    _setStatus('Checking RDAP for Domain Age...');
    try {
      final response = await _dio.get(
        'https://rdap.org/domain/$domain',
        options: Options(receiveTimeout: const Duration(seconds: 4)),
      );
      if (response.statusCode == 200 && response.data['events'] != null) {
        final events = response.data['events'] as List;
        for (var ev in events) {
          if (ev['eventAction'] == 'registration') {
            final dateStr = ev['eventDate'];
            final regDate = DateTime.parse(dateStr);
            final diff = DateTime.now().difference(regDate).inDays;
            return _DomainAgeResult(daysOld: diff);
          }
        }
      }
      return _DomainAgeResult(apiFailed: true);
    } catch (_) {
      return _DomainAgeResult(apiFailed: true);
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF06090F) : const Color(0xFFEBF3FA); // Light blue tint matching app theme
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    // Determine gauge score and status text
    double gaugeScore = 0;
    String statusText = '';
    Color statusColor = Colors.transparent;

    if (_state == _ScanState.done && _result != null) {
      gaugeScore = _result!.riskScore.toDouble();
      if (_result!.verdict == UrlVerdict.dangerous) {
        statusText = 'Unsafe';
        statusColor = Colors.redAccent.shade400;
      } else if (_result!.verdict == UrlVerdict.caution) {
        statusText = 'Suspicious';
        statusColor = Colors.orangeAccent.shade400;
      } else {
        statusText = 'Safe';
        statusColor = Colors.greenAccent.shade400;
      }
    } else if (_state == _ScanState.scanning) {
      statusText = 'Scanning...';
      statusColor = AppTheme.primary;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Link',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Gauge
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: gaugeScore),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return SpeedometerGauge(score: value);
                },
              ),
              const SizedBox(height: 16),
              // Status Text
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ).animate(target: statusText.isNotEmpty ? 1 : 0).fadeIn(),
              
              const SizedBox(height: 48),

              // TextField mimicking the screenshot
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _state == _ScanState.scanning 
                        ? AppTheme.primary 
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 2,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TextField(
                      controller: _controller,
                      enabled: _state != _ScanState.scanning,
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        prefixText: 'https://',
                        prefixStyle: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                      onSubmitted: (_) => _scan(),
                    ),
                    Positioned(
                      left: 24,
                      top: -10,
                      child: Container(
                        color: bg,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Link',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Enter a complete valid url.',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Scan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _state == _ScanState.scanning ? null : _scan,
                  icon: _state == _ScanState.scanning 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.language, color: Colors.white70),
                  label: Text(
                    _state == _ScanState.scanning ? 'Scanning...' : 'Scan URL',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B), // Match screenshot dark pill
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms),

              if (_state == _ScanState.done && _result != null) ...[
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Live Pipeline Checks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._result!.domainChecks.map((check) => _buildCheckItemRow(check)),
              ],

              if (_state == _ScanState.error)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Network error. Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(UrlResult result) {
    Color cardColor;
    Color iconColor;
    IconData icon;
    String title;
    String desc;

    switch (result.verdict) {
      case UrlVerdict.safe:
        cardColor = const Color(0xFF10B981);
        iconColor = Colors.white;
        icon = Icons.check_circle_rounded;
        title = 'Safe Domain';
        desc = 'No threats detected in the pipeline.';
        break;
      case UrlVerdict.caution:
        cardColor = const Color(0xFFF59E0B);
        iconColor = Colors.white;
        icon = Icons.warning_rounded;
        title = 'Caution Advised';
        desc = 'Domain exhibits suspicious patterns.';
        break;
      case UrlVerdict.dangerous:
        cardColor = const Color(0xFFEF4444);
        iconColor = Colors.white;
        icon = Icons.gpp_bad_rounded;
        title = 'Dangerous URL';
        desc = 'Confirmed malware or high risk domain.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Risk Score: ${result.riskScore}/100',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildCheckItemRow(DomainCheckItem check) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    if (check.passed == true) {
      bgColor = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF16A34A);
      icon = Icons.check_circle_rounded;
    } else if (check.passed == false) {
      bgColor = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
    } else {
      bgColor = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF64748B);
      icon = Icons.help_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  check.detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }
}

class _HttpsResult {
  final bool isSecure;
  _HttpsResult({this.isSecure = false});
}

class _SafeBrowsingResult {
  final bool isMalicious;
  final String? threatType;
  final bool apiFailed;
  _SafeBrowsingResult({this.isMalicious = false, this.threatType, this.apiFailed = false});
}

class _VirusTotalResult {
  final int maliciousCount;
  final bool apiFailed;
  _VirusTotalResult({this.maliciousCount = 0, this.apiFailed = false});
}

class _UrlHausResult {
  final bool isListed;
  final bool apiFailed;
  _UrlHausResult({this.isListed = false, this.apiFailed = false});
}

class _DomainAgeResult {
  final int daysOld;
  final bool apiFailed;
  _DomainAgeResult({this.daysOld = -1, this.apiFailed = false});
}

enum UrlVerdict { safe, caution, dangerous }

class UrlResult {
  final String url;
  final String domain;
  final int riskScore;
  final UrlVerdict verdict;
  final Map<String, bool> checks;
  final List<String> warnings;
  final List<String> positives;
  final List<DomainCheckItem> domainChecks;
  final bool isVerifiedSafe;

  UrlResult({
    required this.url,
    required this.domain,
    required this.riskScore,
    required this.verdict,
    required this.checks,
    required this.warnings,
    required this.positives,
    required this.domainChecks,
    required this.isVerifiedSafe,
  });

  factory UrlResult.error(String url) {
    return UrlResult(
      url: url,
      domain: '',
      riskScore: 0,
      verdict: UrlVerdict.caution,
      checks: {},
      warnings: [],
      positives: [],
      domainChecks: [],
      isVerifiedSafe: false,
    );
  }
}

class DomainCheckItem {
  final String name;
  final bool? passed; // null = neutral/unknown
  final String detail;

  DomainCheckItem(this.name, this.passed, this.detail);
}

class SpeedometerGauge extends StatelessWidget {
  final double score; // 0 to 100
  const SpeedometerGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 140, // Height is roughly half of width + padding for the needle base
      child: CustomPaint(
        painter: _SpeedometerPainter(score),
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double score;

  _SpeedometerPainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.butt;
    
    // Draw the 3 arcs (Green, Orange, Red)
    final rect = Rect.fromCircle(center: center, radius: radius - 20);
    
    // Green (0 to 33)
    paint.color = Colors.greenAccent.shade400;
    canvas.drawArc(rect, 3.14159, 3.14159 / 3, false, paint);
    
    // Orange (33 to 66)
    paint.color = Colors.orangeAccent.shade400;
    canvas.drawArc(rect, 3.14159 + (3.14159 / 3), 3.14159 / 3, false, paint);
    
    // Red (66 to 100)
    paint.color = Colors.redAccent.shade400;
    canvas.drawArc(rect, 3.14159 + (2 * 3.14159 / 3), 3.14159 / 3, false, paint);
    
    // Draw needle
    // Map score (0-100) to angle (Pi to 2*Pi)
    // We map a bit inside the bounds so it doesn't go fully horizontal
    double clampedScore = score.clamp(0.0, 100.0);
    final angle = 3.14159 + (clampedScore / 100) * 3.14159;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    final needlePaint = Paint()
      ..color = const Color(0xFFE0E0E0) // Light grey to work on both themes
      ..style = PaintingStyle.fill;
    
    // Draw needle triangle
    final path = Path();
    path.moveTo(0, -6);
    path.lineTo(radius - 10, 0);
    path.lineTo(0, 6);
    path.close();
    
    // Add shadow
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, needlePaint);
    
    // Draw center circle
    canvas.drawCircle(const Offset(0, 0), 16, needlePaint);
    final innerCirclePaint = Paint()..color = Colors.grey.shade400;
    canvas.drawCircle(const Offset(0, 0), 10, innerCirclePaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
