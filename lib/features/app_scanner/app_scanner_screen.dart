import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class AppInfo {
  final String name;
  final String package;
  final List<String> permissions;
  final bool isSystem;
  final String version;
  final int riskScore;
  final RiskLevel riskLevel;
  final List<String> riskReasons;

  const AppInfo({
    required this.name,
    required this.package,
    required this.permissions,
    required this.isSystem,
    required this.version,
    required this.riskScore,
    required this.riskLevel,
    required this.riskReasons,
  });
}

enum RiskLevel { safe, low, medium, high, critical }

// ─── Risk Engine ──────────────────────────────────────────────────────────────
class RiskEngine {
  static const _dangerousPerms = {
    'android.permission.RECORD_AUDIO':        ('🎤 Microphone', 30, 'App aapki awaaz sun sakta hai'),
    'android.permission.CAMERA':              ('📷 Camera', 20, 'App aapka camera use kar sakta hai'),
    'android.permission.READ_CONTACTS':       ('👥 Contacts', 25, 'App aapki contact list padh sakta hai'),
    'android.permission.READ_SMS':            ('💬 SMS Read', 35, 'App aapke SMS padh sakta hai'),
    'android.permission.SEND_SMS':            ('📤 SMS Send', 30, 'App aapki taraf se SMS bhej sakta hai'),
    'android.permission.ACCESS_FINE_LOCATION':('📍 Location (Exact)', 25, 'App aapki exact location track karta hai'),
    'android.permission.ACCESS_BACKGROUND_LOCATION': ('📍 Location 24/7', 40, 'App background mein bhi location track karta hai'),
    'android.permission.READ_CALL_LOG':       ('📞 Call Logs', 35, 'App aapki calls ki history padh sakta hai'),
    'android.permission.PROCESS_OUTGOING_CALLS': ('📞 Call Intercept', 40, 'App aapki calls interrupt kar sakta hai'),
    'android.permission.READ_EXTERNAL_STORAGE': ('📁 Storage Read', 15, 'App aapki files padh sakta hai'),
    'android.permission.WRITE_EXTERNAL_STORAGE': ('💾 Storage Write', 15, 'App aapki files mein likhta hai'),
    'android.permission.GET_ACCOUNTS':        ('🔑 Accounts', 20, 'App aapke Google/other accounts dekh sakta hai'),
    'android.permission.USE_BIOMETRIC':       ('👆 Biometric', 10, 'App fingerprint use karta hai'),
    'android.permission.SYSTEM_ALERT_WINDOW': ('🪟 Overlay', 30, 'App doosri apps ke upar dikhta hai — spyware sign'),
    'android.permission.BIND_ACCESSIBILITY_SERVICE': ('♿ Accessibility', 45, 'Bahut risky — input aur screen monitor kar sakta hai'),
    'android.permission.FOREGROUND_SERVICE':  ('⚙️ Background Run', 10, 'App background mein chalta rehta hai'),
    'android.permission.RECEIVE_BOOT_COMPLETED': ('🔄 Auto-Start', 15, 'App phone on hone pe automatically start hota hai'),
    'android.permission.REQUEST_INSTALL_PACKAGES': ('📦 Install Apps', 35, 'App doosri apps install kar sakta hai — risky'),
    'android.permission.READ_PHONE_STATE':    ('📱 Phone State', 20, 'App aapka phone number aur IMEI padh sakta hai'),
  };

  static AppInfo analyze(Map<String, dynamic> raw) {
    final perms = (raw['permissions'] as List<dynamic>?)?.cast<String>() ?? [];
    final name = raw['name'] as String? ?? 'Unknown';
    final pkg = raw['package'] as String? ?? '';
    final isSystem = raw['isSystem'] as bool? ?? false;
    final version = raw['versionName'] as String? ?? '';

    int score = 0;
    final reasons = <String>[];

    for (final perm in perms) {
      final info = _dangerousPerms[perm];
      if (info != null) {
        score += info.$2;
        reasons.add('${info.$1}: ${info.$3}');
      }
    }

    // Known malicious package patterns
    final pkgLower = pkg.toLowerCase();
    final suspiciousPatterns = [
      'spyware', 'monitor', 'tracker', 'hack', 'keylog', 'stealth',
      'hidden', 'invisible', 'spy', 'remote_control',
    ];
    if (suspiciousPatterns.any((p) => pkgLower.contains(p))) {
      score += 50;
      reasons.add('⚠️ Package naam bahut suspicious hai');
    }

    // Too many permissions for a simple app
    if (perms.length > 20) {
      score += 15;
      reasons.add('📋 Bahut zyada permissions (${perms.length}) — normal apps ke liye unusual');
    }

    // Cap at 100
    score = score.clamp(0, 100);

    final level = score >= 70
        ? RiskLevel.critical
        : score >= 50
            ? RiskLevel.high
            : score >= 30
                ? RiskLevel.medium
                : score >= 15
                    ? RiskLevel.low
                    : RiskLevel.safe;

    return AppInfo(
      name: name,
      package: pkg,
      permissions: perms,
      isSystem: isSystem,
      version: version,
      riskScore: score,
      riskLevel: level,
      riskReasons: reasons.take(5).toList(), // top 5 reasons
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class AppScannerScreen extends StatefulWidget {
  const AppScannerScreen({super.key});

  @override
  State<AppScannerScreen> createState() => _AppScannerScreenState();
}

class _AppScannerScreenState extends State<AppScannerScreen> {
  static const _channel = MethodChannel('com.safesignal/app_scanner');

  _ScanPhase _phase = _ScanPhase.idle;
  List<AppInfo> _apps = [];
  List<AppInfo> _filtered = [];
  String _filterLevel = 'all';
  String _searchQuery = '';
  int _scannedCount = 0;

  // ─── Scan ────────────────────────────────────────────────────
  Future<void> _startScan() async {
    setState(() {
      _phase = _ScanPhase.scanning;
      _scannedCount = 0;
      _apps = [];
    });

    try {
      final rawList = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      final list = rawList ?? [];

      // Analyze progressively
      final analyzed = <AppInfo>[];
      for (int i = 0; i < list.length; i++) {
        final raw = Map<String, dynamic>.from(list[i] as Map);
        analyzed.add(RiskEngine.analyze(raw));
        if (i % 5 == 0) {
          setState(() => _scannedCount = i + 1);
          await Future.delayed(const Duration(milliseconds: 10)); // let UI breathe
        }
      }

      // Sort: critical → high → medium → low → safe
      analyzed.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      setState(() {
        _apps = analyzed;
        _phase = _ScanPhase.done;
      });
      _applyFilter();
    } catch (e) {
      setState(() => _phase = _ScanPhase.error);
    }
  }

  void _applyFilter() {
    List<AppInfo> list = _apps;

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((a) =>
              a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.package.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_filterLevel != 'all') {
      final lvl = RiskLevel.values.firstWhere(
          (l) => l.name == _filterLevel,
          orElse: () => RiskLevel.safe);
      list = list.where((a) => a.riskLevel == lvl).toList();
    }

    setState(() => _filtered = list);
  }

  // ─── Summary stats ──────────────────────────────────────────
  Map<RiskLevel, int> get _counts {
    final m = <RiskLevel, int>{};
    for (final a in _apps) {
      m[a.riskLevel] = (m[a.riskLevel] ?? 0) + 1;
    }
    return m;
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : AppTheme.darkSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Scanner 📱',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: isDark ? Colors.white : AppTheme.darkSurface,
          ),
        ),
      ),
      body: _phase == _ScanPhase.idle
          ? _buildIdle(isDark)
          : _phase == _ScanPhase.scanning
              ? _buildScanning(isDark)
              : _phase == _ScanPhase.error
                  ? _buildError(isDark)
                  : _buildResults(isDark),
    );
  }

  // ─── Idle UI ─────────────────────────────────────────────────
  Widget _buildIdle(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.phonelink_setup_outlined, size: 56, color: Colors.white),
          ).animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),

          const SizedBox(height: 28),
          Text(
            'App Security Scanner',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.darkSurface,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 10),
          Text(
            'Aapke phone ke saare apps ko scan karta hai aur batata hai konsa app kitna safe hai — percentage ke saath.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 32),

          // Feature pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _featurePill('📋 Permissions Check', isDark),
              _featurePill('🎭 Behavior Analysis', isDark),
              _featurePill('⚠️ Risk Scoring', isDark),
              _featurePill('🔴 Danger Detection', isDark),
              _featurePill('📊 Security %', isDark),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.radar, size: 24),
              label: const Text('Scan Shuru Karo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                elevation: 0,
              ),
            ),
          ).animate().fadeIn(delay: 280.ms),

          const SizedBox(height: 16),
          Text(
            '🔒 Sab kuch device pe hi hota hai\nKoi data internet pe nahi jaata',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
          ).animate().fadeIn(delay: 320.ms),
        ],
      ),
    );
  }

  Widget _featurePill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFDDE3F0),
        ),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppTheme.darkSurface)),
    );
  }

  // ─── Scanning UI ─────────────────────────────────────────────
  Widget _buildScanning(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.radar, size: 48, color: Colors.white),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(end: 1.08, duration: 800.ms)
              .then()
              .scaleXY(end: 1.0, duration: 800.ms),

          const SizedBox(height: 28),
          Text(
            'Scan Ho Raha Hai...',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.darkSurface),
          ),
          const SizedBox(height: 10),
          Text(
            '$_scannedCount apps analyze kiye',
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 8,
                backgroundColor: isDark ? AppTheme.darkBorder : const Color(0xFFDDE3F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🔒 Sab device pe — koi data bahar nahi jaata',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  // ─── Error UI ─────────────────────────────────────────────────
  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text('Scan Nahi Ho Saka',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.darkSurface)),
            const SizedBox(height: 12),
            Text(
              'Emulator pe app list limited hoti hai. Real Android device pe try karo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _startScan,
              child: const Text('Dobara Try Karo'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results UI ───────────────────────────────────────────────
  Widget _buildResults(bool isDark) {
    final counts = _counts;
    final critical = counts[RiskLevel.critical] ?? 0;
    final high = counts[RiskLevel.high] ?? 0;
    final medium = counts[RiskLevel.medium] ?? 0;
    final safe = (counts[RiskLevel.safe] ?? 0) + (counts[RiskLevel.low] ?? 0);

    return Column(
      children: [
        // Summary card
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_apps.length} Apps Scan Kiye',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryBadge('$critical', 'Critical 🔴', AppTheme.scamRed),
                    _summaryBadge('$high', 'High ⚠️', AppTheme.cautionAmber),
                    _summaryBadge('$medium', 'Medium 🟡', const Color(0xFFFFB300)),
                    _summaryBadge('$safe', 'Safe ✅', AppTheme.safeGreen),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(),
        ),

        // Filters + Search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  _applyFilter();
                },
                decoration: InputDecoration(
                  hintText: 'App name search karo...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'Sab (${_apps.length})', isDark),
                    _filterChip('critical', 'Critical ($critical) 🔴', isDark),
                    _filterChip('high', 'High ($high) ⚠️', isDark),
                    _filterChip('medium', 'Medium ($medium) 🟡', isDark),
                    _filterChip('safe', 'Safe ($safe) ✅', isDark),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text('Koi app nahi mili',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) => _AppCard(
                    app: _filtered[i],
                    index: i,
                    isDark: isDark,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _summaryBadge(String count, String label, Color color) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _filterChip(String level, String label, bool isDark) {
    final selected = _filterLevel == level;
    return GestureDetector(
      onTap: () {
        _filterLevel = level;
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : (isDark ? AppTheme.darkBorder : const Color(0xFFDDE3F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── App Card ─────────────────────────────────────────────────────────────────
class _AppCard extends StatefulWidget {
  final AppInfo app;
  final int index;
  final bool isDark;

  const _AppCard({required this.app, required this.index, required this.isDark});

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  bool _expanded = false;

  Color get _levelColor {
    switch (widget.app.riskLevel) {
      case RiskLevel.critical: return AppTheme.scamRed;
      case RiskLevel.high:     return const Color(0xFFFF6D00);
      case RiskLevel.medium:   return AppTheme.cautionAmber;
      case RiskLevel.low:      return const Color(0xFF66BB6A);
      case RiskLevel.safe:     return AppTheme.safeGreen;
    }
  }

  String get _levelLabel {
    switch (widget.app.riskLevel) {
      case RiskLevel.critical: return 'CRITICAL 🔴';
      case RiskLevel.high:     return 'HIGH ⚠️';
      case RiskLevel.medium:   return 'MEDIUM 🟡';
      case RiskLevel.low:      return 'LOW 🟢';
      case RiskLevel.safe:     return 'SAFE ✅';
    }
  }

  String get _appEmoji {
    final pkg = widget.app.package.toLowerCase();
    if (pkg.contains('bank') || pkg.contains('pay')) return '🏦';
    if (pkg.contains('camera') || pkg.contains('photo')) return '📷';
    if (pkg.contains('message') || pkg.contains('sms') || pkg.contains('chat')) return '💬';
    if (pkg.contains('social') || pkg.contains('facebook') || pkg.contains('instagram')) return '📱';
    if (pkg.contains('game') || pkg.contains('play')) return '🎮';
    if (pkg.contains('music') || pkg.contains('spotify')) return '🎵';
    if (pkg.contains('map') || pkg.contains('location')) return '🗺️';
    if (pkg.contains('mail') || pkg.contains('gmail')) return '📧';
    if (pkg.contains('shop') || pkg.contains('amazon') || pkg.contains('flipkart')) return '🛒';
    if (widget.app.isSystem) return '⚙️';
    return '📦';
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded
                ? _levelColor.withValues(alpha: 0.4)
                : (widget.isDark ? AppTheme.darkBorder : const Color(0xFFE8EDF8)),
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _levelColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(_appEmoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: widget.isDark ? Colors.white : AppTheme.darkSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          app.package,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark ? Colors.white38 : Colors.black38,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _levelColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _levelLabel,
                          style: TextStyle(
                            color: _levelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${app.riskScore}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _levelColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Risk bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: app.riskScore / 100,
                  minHeight: 6,
                  backgroundColor: widget.isDark ? AppTheme.darkBorder : const Color(0xFFE8EDF8),
                  valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
                ),
              ),
            ),

            // Expanded reasons
            if (_expanded && app.riskReasons.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: _levelColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  border: Border(
                    top: BorderSide(
                      color: _levelColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risky Permissions:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _levelColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...app.riskReasons.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(color: _levelColor, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(r,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: widget.isDark ? Colors.white70 : Colors.black87,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 4),
                    Text(
                      '${app.permissions.length} total permissions',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),

            if (_expanded && app.riskReasons.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Koi suspicious permission nahi mili ✅',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.safeGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.index * 30));
  }
}

enum _ScanPhase { idle, scanning, done, error }
