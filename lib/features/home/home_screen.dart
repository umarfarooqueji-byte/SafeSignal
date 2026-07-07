import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, isDark),
              _buildScoreCard(context, isDark),
              _buildSectionTitle('🔧 Security Tools', context),
              _buildToolsGrid(context, isDark),
              _buildSectionTitle('📊 Aaj Ki Activity', context),
              _buildStatsRow(context, isDark),
              _buildSectionTitle('💡 Safety Tip', context),
              _buildTipCard(context, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Namaste 🙏',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SafeSignal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.darkSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildScoreCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGrad,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security, color: Colors.white70, size: 13),
                      SizedBox(width: 4),
                      Text('Security Score',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.safeGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text('ACHHA 👍',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '72',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, left: 4),
                  child: Text('/100',
                      style: TextStyle(color: Colors.white54, fontSize: 22, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.72,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'App Scanner chalao — score aur badhao!',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppTheme.darkSurface,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context, bool isDark) {
    final tools = [
      _ToolData('🌐', 'URL Scanner', 'Website safe hai ya nahi', const Color(0xFF2979FF), '/url-scanner'),
      _ToolData('📶', 'WiFi Scanner', 'Network security check', const Color(0xFF00897B), '/wifi-scanner'),
      _ToolData('📱', 'App Scanner', 'Installed apps security', const Color(0xFF7C4DFF), '/app-scanner'),
      _ToolData('💬', 'Message Check', 'SMS/WhatsApp analyze', const Color(0xFF00BCD4), '/chat'),
      _ToolData('📰', 'Scam Alerts', 'Aaj ke fraud news', const Color(0xFFE53935), '/feed'),
      _ToolData('📋', 'History', 'Past checks dekho', const Color(0xFFFF6F00), '/history'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final t = tools[i];
          return GestureDetector(
            onTap: () => context.go(t.route),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE8EDF8),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(t.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.darkSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideY(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark) {
    final stats = [
      ('🛡️', '12', 'Scam Pakde'),
      ('🌐', '8', 'Sites Checked'),
      ('📱', '3', 'Risky Apps'),
      ('✅', '30', 'Safe Days'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final s = e.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: e.key < stats.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE8EDF8),
                ),
              ),
              child: Column(
                children: [
                  Text(s.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    s.$2,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    s.$3,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 70 + 200)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.cautionAmber.withValues(alpha: 0.1)
              : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.cautionAmber.withValues(alpha: isDark ? 0.3 : 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.cautionAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('💡', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aaj Ka Tip',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? AppTheme.cautionAmber : const Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Bank kabhi bhi phone pe OTP nahi maangta. Aisa koi bhi call aaye to seedha bank helpline pe call karo aur 1930 pe report karo.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 350.ms),
    );
  }
}

class _ToolData {
  final String emoji, title, subtitle, route;
  final Color color;
  const _ToolData(this.emoji, this.title, this.subtitle, this.color, this.route);
}
