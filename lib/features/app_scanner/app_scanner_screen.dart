import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/arc_gauge.dart';

class AppScannerScreen extends StatefulWidget {
  const AppScannerScreen({super.key});

  @override
  State<AppScannerScreen> createState() => _AppScannerScreenState();
}

class _AppScannerScreenState extends State<AppScannerScreen>
    with TickerProviderStateMixin {
  static const _channel = MethodChannel('com.safesignal/app_scanner');

  _Phase _phase = _Phase.idle;
  List<AppInfo> _allApps = [];
  List<AppInfo> _displayed = [];
  int _tabIndex = 0; // 0=all, 1=thirdParty, 2=highRisk
  String _search = '';
  int _scanned = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _tabIndex = _tabController.index;
          _applyFilters();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _phase = _Phase.scanning;
      _scanned = 0;
      _allApps = [];
    });

    try {
      final rawList = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      final list = rawList ?? [];
      final analyzed = <AppInfo>[];

      for (int i = 0; i < list.length; i++) {
        final raw = Map<String, dynamic>.from(list[i] as Map);
        analyzed.add(RiskEngine.analyze(raw));
        if (i % 5 == 0) {
          setState(() => _scanned = i + 1);
          await Future.delayed(const Duration(milliseconds: 8));
        }
      }

      analyzed.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      setState(() {
        _allApps = analyzed;
        _phase = _Phase.done;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _phase = _Phase.error);
    }
  }

  void _applyFilters() {
    List<AppInfo> list = _allApps;

    // Tab filter
    if (_tabIndex == 1) list = list.where((a) => !a.isSystem).toList();
    if (_tabIndex == 2) list = list.where((a) => a.riskLevel == RiskLevel.high || a.riskLevel == RiskLevel.critical).toList();

    // Search
    if (_search.isNotEmpty) {
      list = list.where((a) =>
          a.name.toLowerCase().contains(_search.toLowerCase()) ||
          a.package.toLowerCase().contains(_search.toLowerCase())).toList();
    }

    setState(() => _displayed = list);
  }

  double get _avgRating {
    if (_allApps.isEmpty) return 0;
    final avgScore = _allApps.fold(0, (sum, a) => sum + a.riskScore) / _allApps.length;
    // Invert: high score = risky = low rating
    return ((100 - avgScore) / 20).clamp(0.0, 5.0);
  }

  Color get _gaugeColor {
    final r = _avgRating;
    if (r >= 4.0) return const Color(0xFF4CAF50);
    if (r >= 2.5) return const Color(0xFFFFB300);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF06090F) : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : const Color(0xFF0D1117), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Apps',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
        ),
        centerTitle: true,
      ),
      body: _phase == _Phase.idle
          ? _buildIdle(isDark)
          : _phase == _Phase.scanning
              ? _buildScanning(isDark)
              : _phase == _Phase.error
                  ? _buildError(isDark)
                  : _buildResults(isDark),
    );
  }

  Widget _buildIdle(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2979FF), Color(0xFF7C4DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.android, size: 56, color: Colors.white),
            ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
            const SizedBox(height: 28),
            Text(
              'App Security Scanner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 10),
            Text(
              'Har installed app ko scan karke batata hai kitni permissions le raha hai aur security rating kya hai (out of 5)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ).animate().fadeIn(delay: 160.ms),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.radar, size: 22),
              label: const Text('Scan Shuru Karo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                elevation: 0,
              ),
            ).animate().fadeIn(delay: 220.ms),
            const SizedBox(height: 14),
            Text(
              '🔒 Sab device pe — koi data bahar nahi jaata',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanning(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: ArcGauge(
              value: _scanned.toDouble(),
              maxValue: 100,
              color: const Color(0xFF2979FF),
              trackColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              strokeWidth: 16,
              sweepDegrees: 210,
              centerChild: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    '$_scanned',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2979FF),
                      height: 1,
                    ),
                  ),
                  Text(
                    'apps',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Scan Ho Raha Hai...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Permissions aur security analyze ho rahi hai',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Scan Nahi Ho Saka',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Real Android phone pe install karo — emulator pe app list limited hoti hai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _startScan,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF)),
              child: const Text('Dobara Try Karo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    final rating = _avgRating;
    final gc = _gaugeColor;
    final critical = _allApps.where((a) => a.riskLevel == RiskLevel.critical).length;
    final high = _allApps.where((a) => a.riskLevel == RiskLevel.high).length;
    final thirdParty = _allApps.where((a) => !a.isSystem).length;

    return Column(
      children: [
        // Top gauge + rating
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Column(
            children: [
              SizedBox(
                width: 200,
                height: 160,
                child: ArcGauge(
                  value: rating,
                  maxValue: 5.0,
                  color: gc,
                  trackColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                  strokeWidth: 20,
                  sweepDegrees: 210,
                  centerChild: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: rating.toStringAsFixed(1).split('.')[0],
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: gc,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: '.${rating.toStringAsFixed(1).split('.')[1]}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: gc.withValues(alpha: 0.7),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '5',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                "Apps' Rating",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          color: isDark ? const Color(0xFF0D1117) : Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2979FF),
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
            indicatorColor: const Color(0xFF2979FF),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
            tabs: [
              Tab(
                icon: const Icon(Icons.android, size: 22),
                text: 'All (${_allApps.length})',
              ),
              Tab(
                icon: const Icon(Icons.download_outlined, size: 22),
                text: 'Third-Party ($thirdParty)',
              ),
              Tab(
                icon: const Icon(Icons.warning_amber, size: 22),
                text: 'High Risk (${critical + high})',
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    _search = v;
                    _applyFilters();
                  },
                  style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0D1117)),
                  decoration: InputDecoration(
                    hintText: 'Search by name or package',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    prefixIcon: Icon(Icons.search,
                        color: isDark ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF161B27) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // App list
        Expanded(
          child: _displayed.isEmpty
              ? Center(
                  child: Text(
                    'Koi app nahi mili',
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _displayed.length,
                  itemBuilder: (context, i) => _AppCard(
                    app: _displayed[i],
                    isDark: isDark,
                    index: i,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── App Card ─────────────────────────────────────────────────────────────────
class _AppCard extends StatefulWidget {
  final AppInfo app;
  final bool isDark;
  final int index;
  const _AppCard({required this.app, required this.isDark, required this.index});

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  bool _expanded = false;

  Color get _ratingColor {
    final r = widget.app.starRating;
    if (r >= 4.0) return const Color(0xFF4CAF50);
    if (r >= 2.5) return const Color(0xFFFFB300);
    return const Color(0xFFE53935);
  }

  String get _appEmoji {
    final pkg = widget.app.package.toLowerCase();
    if (pkg.contains('bank') || pkg.contains('pay') || pkg.contains('upi')) return '🏦';
    if (pkg.contains('camera') || pkg.contains('photo')) return '📷';
    if (pkg.contains('message') || pkg.contains('sms') || pkg.contains('chat') || pkg.contains('whatsapp')) return '💬';
    if (pkg.contains('facebook') || pkg.contains('instagram') || pkg.contains('twitter')) return '📱';
    if (pkg.contains('game')) return '🎮';
    if (pkg.contains('music') || pkg.contains('spotify') || pkg.contains('gaana')) return '🎵';
    if (pkg.contains('map') || pkg.contains('location') || pkg.contains('navigation')) return '🗺️';
    if (pkg.contains('mail') || pkg.contains('gmail')) return '📧';
    if (pkg.contains('shop') || pkg.contains('amazon') || pkg.contains('flipkart') || pkg.contains('myntra')) return '🛒';
    if (pkg.contains('video') || pkg.contains('youtube') || pkg.contains('netflix')) return '🎬';
    if (pkg.contains('airtel') || pkg.contains('jio') || pkg.contains('vi.')) return '📡';
    if (widget.app.isSystem) return '⚙️';
    return '📦';
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final rc = _ratingColor;
    final source = app.isSystem ? 'This is a System App' : 'Downloaded from Play Store';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF161B27) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded
                ? rc.withValues(alpha: 0.4)
                : (widget.isDark ? const Color(0xFF30363D) : const Color(0xFFE8EEF8)),
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // App icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: rc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(_appEmoji, style: const TextStyle(fontSize: 26)),
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
                            color: widget.isDark ? Colors.white : const Color(0xFF0D1117),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.package,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark ? Colors.white38 : Colors.black38,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          source,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark ? Colors.white54 : Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Security Rating',
                        style: TextStyle(
                          fontSize: 9,
                          color: widget.isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        app.starRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: rc,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View details row
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      _expanded ? 'Hide Details' : 'View Details',
                      style: TextStyle(
                        color: rc,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_right,
                      color: rc,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded details
            if (_expanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: rc.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  border: Border(
                    top: BorderSide(color: rc.withValues(alpha: 0.15)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risky Permissions (${app.riskReasons.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: rc,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (app.riskReasons.isEmpty)
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Koi suspicious permission nahi ✅',
                            style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    else
                      ...app.riskReasons.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber, color: rc, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: widget.isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    const SizedBox(height: 6),
                    Text(
                      'Total permissions: ${app.permissions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.index * 25));
  }
}

// ─── Risk Engine ──────────────────────────────────────────────────────────────
enum RiskLevel { safe, low, medium, high, critical }

class AppInfo {
  final String name, package, version;
  final List<String> permissions;
  final bool isSystem;
  final int riskScore;
  final RiskLevel riskLevel;
  final List<String> riskReasons;

  const AppInfo({
    required this.name, required this.package, required this.version,
    required this.permissions, required this.isSystem,
    required this.riskScore, required this.riskLevel, required this.riskReasons,
  });

  // 0-100 riskScore → 0-5 star (inverted)
  double get starRating => ((100 - riskScore) / 20).clamp(0.0, 5.0);
}

class RiskEngine {
  static const _dangerPerms = {
    'android.permission.RECORD_AUDIO': ('🎤 Microphone', 30, 'App awaaz sun sakta hai'),
    'android.permission.CAMERA': ('📷 Camera', 20, 'App camera use kar sakta hai'),
    'android.permission.READ_CONTACTS': ('👥 Contacts', 25, 'App contacts padh sakta hai'),
    'android.permission.READ_SMS': ('💬 SMS Read', 35, 'App SMS padh sakta hai'),
    'android.permission.SEND_SMS': ('📤 SMS Send', 30, 'App SMS bhej sakta hai'),
    'android.permission.ACCESS_FINE_LOCATION': ('📍 Location', 25, 'App exact location track karta hai'),
    'android.permission.ACCESS_BACKGROUND_LOCATION': ('📍 Location 24/7', 40, 'App background mein bhi location track karta hai'),
    'android.permission.READ_CALL_LOG': ('📞 Call Logs', 35, 'App call history padh sakta hai'),
    'android.permission.PROCESS_OUTGOING_CALLS': ('📞 Call Intercept', 40, 'App calls intercept kar sakta hai'),
    'android.permission.GET_ACCOUNTS': ('🔑 Accounts', 20, 'App aapke accounts dekh sakta hai'),
    'android.permission.SYSTEM_ALERT_WINDOW': ('🪟 Overlay', 30, 'App doosri apps ke upar dikhta hai'),
    'android.permission.BIND_ACCESSIBILITY_SERVICE': ('♿ Accessibility', 45, 'Bahut risky — screen monitor kar sakta hai'),
    'android.permission.REQUEST_INSTALL_PACKAGES': ('📦 Install Apps', 35, 'App doosri apps install kar sakta hai'),
    'android.permission.READ_PHONE_STATE': ('📱 Phone State', 20, 'App phone number aur IMEI padh sakta hai'),
    'android.permission.WRITE_SETTINGS': ('⚙️ System Settings', 25, 'App system settings change kar sakta hai'),
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
      final info = _dangerPerms[perm];
      if (info != null) {
        score += info.$2;
        reasons.add('${info.$1}: ${info.$3}');
      }
    }

    if (perms.length > 25) {
      score += 15;
      reasons.add('📋 Bahut zyada permissions (${perms.length}) le raha hai');
    }

    final pkgLower = pkg.toLowerCase();
    if (['spyware', 'tracker', 'hack', 'spy', 'stealth'].any((p) => pkgLower.contains(p))) {
      score += 50;
      reasons.add('⚠️ Package naam suspicious hai');
    }

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
      name: name, package: pkg, version: version, permissions: perms,
      isSystem: isSystem, riskScore: score, riskLevel: level,
      riskReasons: reasons.take(6).toList(),
    );
  }
}

enum _Phase { idle, scanning, done, error }
