import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  static const _channel = MethodChannel('com.safesignal/app_scanner');
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _requestAllPermissions();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestAllPermissions() async {
    await [Permission.sms, Permission.phone, Permission.notification].request();
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(settingsProvider).language;
    final bg = isDark ? const Color(0xFF060A12) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(isDark: isDark, lang: lang),
              const SizedBox(height: 18),
              _PremiumShieldHero(
                isDark: isDark,
                pulseCtrl: _pulseCtrl,
                rotateCtrl: _rotateCtrl,
                lang: lang,
              ),
              const SizedBox(height: 20),
              _ProtectionStatusBar(isDark: isDark, lang: lang),
              const SizedBox(height: 24),
              _SectionLabel(
                label: lang == 'hi' ? 'SECURITY TOOLS' : 'SECURITY TOOLS',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _PremiumQuickGrid(isDark: isDark, lang: lang),
              const SizedBox(height: 20),
              _SectionLabel(
                label: lang == 'hi' ? 'AJ KA THREAT' : 'TODAY\'S THREAT',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _ThreatTipBanner(isDark: isDark, lang: lang),
              const SizedBox(height: 20),
              _EmergencyBanner(isDark: isDark, lang: lang),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium Top Bar ──────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _TopBar({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String greeting;
    if (lang == 'hi') {
      greeting = now.hour < 12
          ? 'Subah Ki Shuruaat 🌅'
          : now.hour < 17
              ? 'Dopahar Mubarak ☀️'
              : 'Shaam Ka Safar 🌙';
    } else {
      greeting = now.hour < 12
          ? 'Good Morning 🌅'
          : now.hour < 17
              ? 'Good Afternoon ☀️'
              : 'Good Evening 🌙';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Safe',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2979FF),
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Signal',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF060A12),
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: ' 🛡️',
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _GlassIconBtn(CupertinoIcons.bell, isDark, () {}),
          const SizedBox(width: 8),
          _GlassIconBtn(CupertinoIcons.gear_alt, isDark, () => GoRouter.of(context).go('/settings')),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.08);
  }
}

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _GlassIconBtn(this.icon, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFDDE3F8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white60 : const Color(0xFF2979FF),
          size: 22,
        ),
      ),
    );
  }
}

// ─── Premium Shield Hero ──────────────────────────────────────────────────────
class _PremiumShieldHero extends StatelessWidget {
  final bool isDark;
  final AnimationController pulseCtrl;
  final AnimationController rotateCtrl;
  final String lang;
  const _PremiumShieldHero({
    required this.isDark,
    required this.pulseCtrl,
    required this.rotateCtrl,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1B35) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2979FF).withValues(alpha: 0.2)
                : const Color(0xFF2979FF).withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2979FF).withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle circuit pattern background
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AnimatedBuilder(
                  animation: rotateCtrl,
                  builder: (context, child) => CustomPaint(
                    painter: _CircuitPainter(rotateCtrl.value, isDark: isDark),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
              child: Column(
                children: [
                  // Shield animation
                  AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (context, child) {
                      final pulse = 0.94 + 0.06 * pulseCtrl.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140 * pulse,
                            height: 140 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2979FF).withValues(alpha: isDark ? 0.12 * pulse : 0.08 * pulse),
                                width: 1,
                              ),
                            ),
                          ),
                          Container(
                            width: 116 * pulse,
                            height: 116 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2979FF).withValues(alpha: isDark ? 0.18 * pulse : 0.12 * pulse),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 90 * pulse,
                            height: 90 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF2979FF).withValues(alpha: isDark ? 0.25 * pulse : 0.1 * pulse),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Shield icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3D8BFF), Color(0xFF7C4DFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2979FF).withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).fade(
                          begin: 0.3,
                          end: 1,
                          duration: 1200.ms,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lang == 'hi' ? 'SURAKSHIT HAI' : 'PROTECTED',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lang == 'hi'
                        ? 'Aapka phone SafeSignal AI ki\nnigrani mein hai 🔒'
                        : 'Your phone is under\nSafeSignal AI protection 🔒',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.45),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        value: '98%',
                        label: lang == 'hi' ? 'Scam\nDetection' : 'Scam\nDetection',
                        color: const Color(0xFF4CAF50),
                        icon: CupertinoIcons.shield_lefthalf_fill,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        value: '24/7',
                        label: lang == 'hi' ? 'SMS\nWatchdog' : 'SMS\nWatchdog',
                        color: const Color(0xFF2979FF),
                        icon: CupertinoIcons.antenna_radiowaves_left_right,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        value: '4.8★',
                        label: lang == 'hi' ? 'App\nRating' : 'App\nRating',
                        color: const Color(0xFFFFB300),
                        icon: CupertinoIcons.star_fill,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  final bool isDark;
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.4),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Protection Status Bar ────────────────────────────────────────────────────
class _ProtectionStatusBar extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _ProtectionStatusBar({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatusItem(
        label: lang == 'hi' ? 'SMS Guard' : 'SMS Guard',
        icon: CupertinoIcons.chat_bubble_text,
        active: true,
        color: const Color(0xFF4CAF50),
        route: '/sms-inbox',
      ),
      _StatusItem(
        label: lang == 'hi' ? 'Call Shield' : 'Call Shield',
        icon: CupertinoIcons.phone_arrow_down_left,
        active: true,
        color: const Color(0xFF2979FF),
        route: '/call-shield',
      ),
      _StatusItem(
        label: lang == 'hi' ? 'Email Guard' : 'Email Guard',
        icon: CupertinoIcons.mail,
        active: true,
        color: const Color(0xFF7C4DFF),
        route: '/email-breach',
      ),
      _StatusItem(
        label: lang == 'hi' ? 'WiFi Scan' : 'WiFi Scan',
        icon: CupertinoIcons.wifi,
        active: false,
        color: const Color(0xFF90A4AE),
        route: '/wifi-scanner',
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () {
              if (item.route != null) {
                GoRouter.of(context).go(item.route!);
              }
            },
            child: Container(
              width: 132,
              margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1724) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.active
                    ? item.color.withValues(alpha: 0.3)
                    : (isDark
                        ? const Color(0xFF2A3347)
                        : const Color(0xFFDDE3F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: item.active
                      ? item.color.withValues(alpha: isDark ? 0.12 : 0.06)
                      : Colors.transparent,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 15, color: item.color),
                    ),
                    const Spacer(),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: item.active ? item.color : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        boxShadow: item.active
                            ? [
                                BoxShadow(
                                  color: item.color.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF060A12),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.active
                          ? (lang == 'hi' ? 'Active' : 'Active')
                          : (lang == 'hi' ? 'Check karo' : 'Check'),
                      style: TextStyle(
                        fontSize: 10,
                        color: item.active ? item.color : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideX(begin: 0.08);
        },
      ),
    );
  }
}

class _StatusItem {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final String? route;
  const _StatusItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    this.route,
  });
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Quick Grid ───────────────────────────────────────────────────────
class _PremiumQuickGrid extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _PremiumQuickGrid({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool(
        label: lang == 'hi' ? 'Device\nAudit' : 'Device\nAudit',
        icon: CupertinoIcons.device_phone_portrait,
        color: const Color(0xFFF44336), // Red color for system audit
        route: '/device-audit',
        isHighlighted: true,
      ),
      _Tool(
        label: lang == 'hi' ? 'Website\nChecker' : 'Website\nChecker',
        icon: CupertinoIcons.globe,
        color: const Color(0xFF00897B),
        route: '/url-scanner',
      ),
      _Tool(
        label: lang == 'hi' ? 'Dark Web\nScan' : 'Dark Web\nScan',
        icon: CupertinoIcons.mail_solid,
        color: const Color(0xFFE91E63),
        route: '/email-breach',
      ),
      _Tool(
        label: lang == 'hi' ? 'App\nAudit' : 'App\nAudit',
        icon: CupertinoIcons.search_circle_fill,
        color: const Color(0xFF7C4DFF),
        route: '/app-scanner',
      ),
      _Tool(
        label: lang == 'hi' ? 'UPI & QR\nScanner' : 'UPI & QR\nScanner',
        icon: CupertinoIcons.qrcode_viewfinder,
        color: const Color(0xFF00ACC1),
        route: '/upi-scanner',
        isHighlighted: false,
      ),
      _Tool(
        label: lang == 'hi' ? 'Call\nShield' : 'Call\nShield',
        icon: CupertinoIcons.phone_fill,
        color: const Color(0xFFFF6F00),
        route: '/call-shield',
      ),
      _Tool(
        label: lang == 'hi' ? 'SMS\nInbox' : 'SMS\nInbox',
        icon: CupertinoIcons.chat_bubble_2_fill,
        color: const Color(0xFF4CAF50),
        route: '/sms-inbox',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.87,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final t = tools[i];
          return GestureDetector(
            onTap: () => GoRouter.of(context).go(t.route),
            child: AnimatedContainer(
              duration: 200.ms,
              decoration: BoxDecoration(
                gradient: t.isHighlighted
                    ? LinearGradient(
                        colors: [
                          t.color.withValues(alpha: 0.15),
                          t.color.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: t.isHighlighted
                    ? null
                    : (isDark ? const Color(0xFF0F1724) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: t.isHighlighted
                      ? t.color.withValues(alpha: 0.4)
                      : (isDark
                          ? const Color(0xFF2A3347)
                          : const Color(0xFFDDE3F0)),
                  width: t.isHighlighted ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: t.isHighlighted
                        ? t.color.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: t.isHighlighted ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.color, t.color.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: t.color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(t.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      height: 1.3,
                      color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF0D1117),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 60 + i * 50)).scale(
                  begin: const Offset(0.88, 0.88),
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final String label, route;
  final IconData icon;
  final Color color;
  final bool isHighlighted;
  const _Tool({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    this.isHighlighted = false,
  });
}

// ─── Threat Tip Banner ────────────────────────────────────────────────────────
class _ThreatTipBanner extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _ThreatTipBanner({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE53935).withValues(alpha: isDark ? 0.14 : 0.07),
              const Color(0xFFFF8A80).withValues(alpha: isDark ? 0.06 : 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: isDark ? 0.3 : 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.campaign_outlined,
                  color: Color(0xFFE53935), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'hi' ? '🚨 Aaj Ka Threat Alert' : '🚨 Today\'s Threat Alert',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang == 'hi'
                        ? 'Ajkal "CBI Digital Arrest" calls, "Bijli katne" wale SMS aur fake UPI payment apps bahut aa rahe hain. Koi bhi link pe click karne se pehle SafeSignal se check karo.'
                        : 'Recent surge in "CBI Digital Arrest" calls, "electricity cut" SMS scams and fake UPI apps. Always check with SafeSignal before clicking any link.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).go('/feed'),
                    child: Row(
                      children: [
                        Text(
                          lang == 'hi' ? 'Aur alerts dekhein' : 'View more alerts',
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 13, color: Color(0xFFE53935)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 380.ms),
    );
  }
}

// ─── Emergency Banner ─────────────────────────────────────────────────────────
class _EmergencyBanner extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _EmergencyBanner({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'hi'
                    ? '📞 Cybercrime Helpline: 1930 — Abhi call karein!'
                    : '📞 Cybercrime Helpline: 1930 — Call now!',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD32F2F).withValues(alpha: isDark ? 0.2 : 0.1),
                const Color(0xFFB71C1C).withValues(alpha: isDark ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Text('🆘', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'hi' ? 'Cybercrime Emergency' : 'Cybercrime Emergency',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                    Text(
                      lang == 'hi'
                          ? 'Helpline: 1930 | cybercrime.gov.in'
                          : 'Helpline: 1930 | cybercrime.gov.in',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  lang == 'hi' ? 'Call' : 'Call',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 480.ms),
    );
  }
}

// ─── Circuit Board Painter ────────────────────────────────────────────────────
class _CircuitPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _CircuitPainter(this.progress, {this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: isDark ? 0.04 : 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const r = 22.0;
    const h = r * 0.866;
    for (double x = 0; x < size.width + r * 2; x += r * 1.5) {
      for (double y = 0; y < size.height + h * 2; y += h * 2) {
        final offset = (x ~/ (r * 1.5)).isOdd ? h : 0.0;
        _drawHex(canvas, paint, Offset(x, y + offset), r);
      }
    }

    // Scan line
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF2979FF).withValues(alpha: isDark ? 0.08 : 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final scanY = (size.height + 80) * progress - 40;
    canvas.drawRect(
      Rect.fromLTWH(0, scanY, size.width, 40),
      scanPaint,
    );
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => old.progress != progress || old.isDark != isDark;
}
