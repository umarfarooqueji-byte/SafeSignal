import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/verdict_model.dart';

class VerdictScreen extends StatelessWidget {
  final VerdictModel verdict;
  const VerdictScreen({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.verdictColor(verdict.verdict);
    final bgColor = AppTheme.verdictBgColor(verdict.verdict);
    final emoji = AppTheme.verdictEmoji(verdict.verdict);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: color,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Text(emoji, style: const TextStyle(fontSize: 72))
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      Text(
                        verdict.verdict == 'SCAM'
                            ? 'SCAM HAI!'
                            : verdict.verdict == 'LIKELY_SAFE'
                                ? 'SAFE HAI ✓'
                                : 'SAVDHAN RAHO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                      const SizedBox(height: 8),
                      // Confidence bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Text(
                              '${(verdict.confidence * 100).toStringAsFixed(0)}% Confidence',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: verdict.confidence,
                                backgroundColor: Colors.white30,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 8,
                              ),
                            ).animate().scaleX(delay: 400.ms, duration: 600.ms, alignment: Alignment.centerLeft),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badges
                    Wrap(
                      spacing: 8,
                      children: [
                        _Badge(label: verdict.scamType.replaceAll('_', ' ').toUpperCase(), color: color),
                        if (verdict.escalated)
                          _Badge(
                            label: '🔍 DEEP ANALYSIS USED',
                            color: Colors.purple.shade700,
                            icon: Icons.analytics,
                          ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 20),

                    // Trend note
                    if (verdict.trendNote != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Text('📈', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TREND ALERT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(verdict.trendNote!, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 16),

                    // WHY section
                    _SectionCard(
                      title: 'KYUN? / WHY?',
                      icon: Icons.help_outline,
                      color: color,
                      delay: 500,
                      child: Column(
                        children: verdict.why
                            .map((w) => _BulletItem(text: w, color: color))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // WHAT TO DO section
                    _SectionCard(
                      title: 'AB KYA KARO? / WHAT TO DO?',
                      icon: Icons.checklist,
                      color: color,
                      delay: 600,
                      child: Column(
                        children: verdict.whatToDo
                            .map((w) => _BulletItem(text: w, color: color, isTick: true))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Feedback buttons
                    const Text(
                      'Kya yeh verdict sahi tha?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendFeedback(context, true),
                            icon: const Icon(Icons.thumb_up_outlined),
                            label: const Text('Sahi tha ✓'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.safeGreen,
                              side: const BorderSide(color: AppTheme.safeGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendFeedback(context, false),
                            icon: const Icon(Icons.thumb_down_outlined),
                            label: const Text('Galat ✗'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.scamRed,
                              side: const BorderSide(color: AppTheme.scamRed),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 12),

                    // Share button
                    ElevatedButton.icon(
                      onPressed: () => _shareVerdict(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Parivaar ke saath share karein'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 20),

                    // Disclaimer footer
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '⚠️ ${verdict.disclaimer}\n\n📞 Asli fraud report karo: 1930',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 900.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendFeedback(BuildContext context, bool correct) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Shukriya! Feedback mila ✓' : 'Shukriya! Hum sudhar karenge.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareVerdict(BuildContext context) {
    // TODO: integrate share_plus in Step 10
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature aane wali hai!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final int delay;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.2);
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  final bool isTick;

  const _BulletItem({required this.text, required this.color, this.isTick = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isTick ? Icons.check_circle_outline : Icons.circle,
            color: color,
            size: isTick ? 18 : 8,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
