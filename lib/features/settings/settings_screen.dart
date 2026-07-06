import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

// Settings state
class SettingsState {
  final String language;
  final double textScale;
  final bool notificationsEnabled;

  const SettingsState({
    this.language = 'hi',
    this.textScale = 1.0,
    this.notificationsEnabled = true,
  });

  SettingsState copyWith({String? language, double? textScale, bool? notificationsEnabled}) {
    return SettingsState(
      language: language ?? this.language,
      textScale: textScale ?? this.textScale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

// Riverpod v3 Notifier
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      language: prefs.getString(AppConstants.prefLanguage) ?? 'hi',
      textScale: prefs.getDouble(AppConstants.prefTextScale) ?? 1.0,
      notificationsEnabled: prefs.getBool(AppConstants.prefNotifications) ?? true,
    );
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguage, lang);
    state = state.copyWith(language: lang);
  }

  Future<void> setTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefTextScale, scale);
    state = state.copyWith(textScale: scale);
  }

  Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefNotifications, value);
    state = state.copyWith(notificationsEnabled: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          _SettingsSection(
            title: 'Bhasha / Language',
            icon: Icons.language,
            child: Row(
              children: [
                Expanded(
                  child: _LangOption(
                    label: 'हिंदी',
                    selected: settings.language == 'hi',
                    onTap: () => notifier.setLanguage('hi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LangOption(
                    label: 'English',
                    selected: settings.language == 'en',
                    onTap: () => notifier.setLanguage('en'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Text Size
          _SettingsSection(
            title: 'Akshar Ka Aakaar / Text Size',
            icon: Icons.text_fields,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TextSizeButton(
                        label: 'Normal\nसामान्य',
                        scale: 1.0,
                        current: settings.textScale,
                        onTap: () => notifier.setTextScale(1.0)),
                    _TextSizeButton(
                        label: 'Bada\nबड़ा',
                        scale: 1.2,
                        current: settings.textScale,
                        onTap: () => notifier.setTextScale(1.2)),
                    _TextSizeButton(
                        label: 'Bahut Bada\nबहुत बड़ा',
                        scale: 1.5,
                        current: settings.textScale,
                        onTap: () => notifier.setTextScale(1.5)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Preview: Ye ek udaharan hai.',
                  style: TextStyle(fontSize: 16 * settings.textScale),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notifications
          _SettingsSection(
            title: 'Suchnayen / Notifications',
            icon: Icons.notifications_outlined,
            child: SwitchListTile(
              title: const Text('Daily Scam Alerts'),
              subtitle: const Text('Roz naye scam ke baare mein jaankari'),
              value: settings.notificationsEnabled,
              onChanged: notifier.setNotifications,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 16),

          // About
          _SettingsSection(
            title: 'App ke Baare Mein / About',
            icon: Icons.info_outline,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AboutRow(icon: '🛡️', label: 'SafeSignal v1.0.0'),
                _AboutRow(icon: '📞', label: 'Cybercrime Helpline: 1930'),
                _AboutRow(icon: '🔒', label: 'Aapka data safe hai'),
                _AboutRow(icon: '🆓', label: 'Bilkul muft — koi fees nahi'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              '⚠️ SafeSignal ek AI assistant hai. Asli fraud ke liye 1930 pe call karein.\n\n'
              'SafeSignal is an AI assistant. For real fraud, call 1930.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}

class _TextSizeButton extends StatelessWidget {
  final String label;
  final double scale;
  final double current;
  final VoidCallback onTap;

  const _TextSizeButton(
      {required this.label,
      required this.scale,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = (scale - current).abs() < 0.01;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String icon;
  final String label;

  const _AboutRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
