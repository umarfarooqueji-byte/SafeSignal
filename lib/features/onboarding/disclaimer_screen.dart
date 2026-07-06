import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _agreed = false;

  Future<void> _proceed() async {
    if (!_agreed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
    if (mounted) context.go('/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text('⚠️', style: TextStyle(fontSize: 64), textAlign: TextAlign.center)
                  .animate()
                  .scale(duration: 500.ms),
              const SizedBox(height: 24),
              Text(
                'Zaroori Baat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              Text(
                'Important Disclaimer',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'SafeSignal shak wale messages pehchanne mein madad karta hai, lekin ye ek AI tool hai — insan nahi.\n\n'
                      'SafeSignal helps identify suspicious messages, but it is an AI tool — not a human expert.\n\n'
                      '🚨 Asli fraud ke liye:\nFor real fraud, always call:\n\n'
                      '📞 1930\n(National Cybercrime Helpline)\n\n'
                      'SafeSignal ki raay final nahi hai. Apna vivek bhi istamaal karein.\n'
                      "SafeSignal's verdict is not final. Use your own judgment too.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Mujhe samajh aa gaya, main sahamat hoon\nI understand and agree',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _agreed ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _agreed ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Shuru Karein / Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
