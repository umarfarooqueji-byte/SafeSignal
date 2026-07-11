import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class CallShieldScreen extends StatefulWidget {
  const CallShieldScreen({super.key});

  @override
  State<CallShieldScreen> createState() => _CallShieldScreenState();
}

class _CallShieldScreenState extends State<CallShieldScreen> {
  bool _isPhonePermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.phone.status;
    setState(() {
      _isPhonePermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.phone.request();
    setState(() {
      _isPhonePermissionGranted = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060A12) : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Call Shield',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Color(0xFF0D1117),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D1117), size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero card
              Column(
                children: [
                  const Icon(
                    Icons.call_outlined,
                    color: AppTheme.primary,
                    size: 56,
                  ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
                  const SizedBox(height: 16),
                  const Text(
                    'Advanced Call Protection',
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
                    'Monitors incoming calls for suspected scammers, CBI/Police digital arrest threats, and lottery traps.',
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

              // Status check
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1724) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isPhonePermissionGranted
                        ? const Color(0xFF00C853).withValues(alpha: 0.3)
                        : const Color(0xFFFFB300).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPhonePermissionGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _isPhonePermissionGranted ? const Color(0xFF00C853) : const Color(0xFFFFB300),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPhonePermissionGranted ? 'Active Call Shield' : 'Permission Required',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPhonePermissionGranted
                                ? 'SafeSignal is monitoring calls in the background.'
                                : 'Grant phone permissions to flag known spam callers.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isPhonePermissionGranted)
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

              // Threat education
              Text(
                'SUSPICIOUS CALL ALERTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _TipCard(
                title: 'Digital Arrest Threat',
                desc: 'If a caller claims they are from CBI, Customs, or Police and forces you to stay on a video call, disconnect immediately. No real agency arrests via video.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _TipCard(
                title: 'WhatsApp International Calls',
                desc: 'Calls starting with +92, +84, etc., from unknown numbers claiming to be KBC lottery or job offers are 100% scam calls.',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title, desc;
  final bool isDark;

  const _TipCard({
    required this.title,
    required this.desc,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1724) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF202A3C) : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF7C4DFF), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
