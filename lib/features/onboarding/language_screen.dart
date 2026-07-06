import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLang = 'hi';

  Future<void> _selectLanguage(String lang) async {
    setState(() => _selectedLang = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguage, lang);
    if (mounted) context.go('/disclaimer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🌐', style: TextStyle(fontSize: 64), textAlign: TextAlign.center)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                'Apni Bhasha Chunein',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              Text(
                'Choose Your Language',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              _LangCard(
                flag: '🇮🇳',
                lang: 'हिंदी',
                subtitle: 'Hindi',
                selected: _selectedLang == 'hi',
                onTap: () => _selectLanguage('hi'),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
              const SizedBox(height: 16),
              _LangCard(
                flag: '🇬🇧',
                lang: 'English',
                subtitle: 'English',
                selected: _selectedLang == 'en',
                onTap: () => _selectLanguage('en'),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final String flag;
  final String lang;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangCard({
    required this.flag,
    required this.lang,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selected ? Theme.of(context).colorScheme.primary : null,
                      ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ],
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
