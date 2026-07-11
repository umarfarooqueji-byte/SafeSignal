import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class OtpGuardScreen extends StatefulWidget {
  const OtpGuardScreen({super.key});

  @override
  State<OtpGuardScreen> createState() => _OtpGuardScreenState();
}

class _OtpGuardScreenState extends State<OtpGuardScreen> {
  bool _isSmsPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    setState(() {
      _isSmsPermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _isSmsPermissionGranted = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060A12) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('OTP Guard 🔐'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF2979FF),
                    size: 56,
                  ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
                  const SizedBox(height: 16),
                  const Text(
                    'Real-time OTP Protection',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: -0.06),
                  const SizedBox(height: 8),
                  Text(
                    'SafeSignal runs in the background to monitor OTP theft attempts and unauthorized forwarding.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
              const SizedBox(height: 24),

              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1724) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isSmsPermissionGranted
                        ? const Color(0xFF00C853).withValues(alpha: 0.3)
                        : const Color(0xFFFFB300).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSmsPermissionGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _isSmsPermissionGranted ? const Color(0xFF00C853) : const Color(0xFFFFB300),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSmsPermissionGranted ? 'Active Shield On' : 'Permission Required',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSmsPermissionGranted
                                ? 'SafeSignal is actively watching your incoming SMS.'
                                : 'Grant SMS permission to scan scam patterns.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isSmsPermissionGranted)
                      ElevatedButton(
                        onPressed: _requestPermission,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Allow', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 24),

              // Checklist details
              Text(
                'CRITICAL SECURITY CHECKS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _CheckItem(
                title: 'No SMS Forwarding Active',
                desc: 'Scammers activate *21* forwarding to steal OTPs.',
                isSecure: true,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _CheckItem(
                title: 'Clean Clipboard Monitor',
                desc: 'Clipboard content is guarded from malicious apps.',
                isSecure: true,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _CheckItem(
                title: 'Phishing Keyword Detector',
                desc: 'Alerts instantly if scam keywords match incoming messages.',
                isSecure: true,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String title, desc;
  final bool isSecure;
  final bool isDark;

  const _CheckItem({
    required this.title,
    required this.desc,
    required this.isSecure,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1724) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF202A3C) : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF00C853), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
