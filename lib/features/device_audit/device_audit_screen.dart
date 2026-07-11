import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_device/safe_device.dart';
import 'dart:io';
import '../../core/services/supabase_service.dart';

import '../../core/widgets/arc_gauge.dart';

class DeviceAuditScreen extends StatefulWidget {
  const DeviceAuditScreen({super.key});

  @override
  State<DeviceAuditScreen> createState() => _DeviceAuditScreenState();
}

class _DeviceAuditScreenState extends State<DeviceAuditScreen> {
  _Phase _phase = _Phase.idle;
  _AuditResult? _result;

  Future<void> _startAudit() async {
    setState(() {
      _phase = _Phase.scanning;
    });

    // Simulate hacker scanning animation time
    await Future.delayed(const Duration(seconds: 3));

    bool isJailBroken = false;
    bool isRealDevice = true;
    bool isOnExternalStorage = false;
    bool isDevelopmentModeEnable = false;

    try {
      isJailBroken = await SafeDevice.isJailBroken;
      isRealDevice = await SafeDevice.isRealDevice;
      isOnExternalStorage = await SafeDevice.isOnExternalStorage;
      isDevelopmentModeEnable = await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      debugPrint('SafeDevice error: $e');
    }

    int score = 100;
    final checks = <_Check>[];

    // 1. Root / Jailbreak Check
    if (isJailBroken) {
      score -= 50;
      checks.add(const _Check(
        label: 'Root / Jailbreak Status',
        detail: 'DANGER: Device root hai! Hackers ko system-level access mil sakta hai. Banking apps risk mein hain.',
        level: _Level.critical,
        icon: Icons.lock_open,
      ));
    } else {
      checks.add(const _Check(
        label: 'System Integrity',
        detail: 'Device secure hai. Koi root/jailbreak detect nahi hua.',
        level: _Level.safe,
        icon: Icons.shield,
      ));
    }

    // 2. Developer Options / ADB Check
    if (isDevelopmentModeEnable && Platform.isAndroid) {
      score -= 30;
      checks.add(const _Check(
        label: 'Developer Options (ADB)',
        detail: 'USB Debugging ON hai! Agar phone kisi ke haath laga, toh wo bina password ke data nikal sakta hai.',
        level: _Level.danger,
        icon: Icons.developer_mode,
      ));
    } else {
      checks.add(const _Check(
        label: 'Developer Modes',
        detail: 'Developer options secure hain.',
        level: _Level.safe,
        icon: Icons.developer_mode,
      ));
    }

    // 3. Emulator Check
    if (!isRealDevice) {
      score -= 40;
      checks.add(const _Check(
        label: 'Hardware Check',
        detail: 'Emulator detect hua! App real phone pe nahi chal raha. Yeh sandbox ya hacker lab ho sakta hai.',
        level: _Level.critical,
        icon: Icons.phone_android,
      ));
    } else {
      checks.add(const _Check(
        label: 'Hardware Check',
        detail: 'Genuine hardware detected.',
        level: _Level.safe,
        icon: Icons.smartphone,
      ));
    }

    // 4. External Storage
    if (isOnExternalStorage) {
      score -= 10;
      checks.add(const _Check(
        label: 'App Storage',
        detail: 'App external SD card pe install hai, jahan data tampering thoda aasan hota hai.',
        level: _Level.warning,
        icon: Icons.sd_storage,
      ));
    } else {
      checks.add(const _Check(
        label: 'App Storage',
        detail: 'App secure internal memory mein hai.',
        level: _Level.safe,
        icon: Icons.memory,
      ));
    }

    score = score.clamp(0, 100);

    setState(() {
      _phase = _Phase.done;
      _result = _AuditResult(
        score: score,
        rating: (score / 20).clamp(0.0, 5.0),
        checks: checks,
      );
    });

    // Save to Supabase
    try {
      await SupabaseService().saveScanHistory(
        scanType: 'DEVICE',
        target: 'Local Device',
        status: score >= 80 ? 'SAFE' : (score >= 50 ? 'WARNING' : 'DANGER'),
        details: {
          'score': score,
          'failed_checks': checks.where((c) => c.level != _Level.safe).map((c) => c.label).toList(),
        },
      );
    } catch (e) {
      debugPrint('Supabase save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF06090F) : const Color(0xFFEBF3FA); // Light blue tint matching app theme
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    double gaugeScore = 0;
    String statusText = '';
    Color statusColor = Colors.transparent;

    if (_phase == _Phase.done && _result != null) {
      gaugeScore = _result!.rating;
      if (_result!.score >= 80) {
        statusText = 'Secure';
        statusColor = const Color(0xFF10B981);
      } else if (_result!.score >= 50) {
        statusText = 'Warning';
        statusColor = const Color(0xFFFFB300);
      } else {
        statusText = 'Compromised';
        statusColor = const Color(0xFFE53935);
      }
    } else if (_phase == _Phase.scanning) {
      statusText = 'Scanning...';
      statusColor = const Color(0xFF7C4DFF);
    } else {
      statusText = 'Ready to Scan';
      statusColor = isDark ? Colors.white70 : Colors.black54;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Device Security',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Gauge
              SizedBox(
                width: 240,
                height: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: gaugeScore),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ArcGauge(
                      value: value,
                      maxValue: 5.0,
                      color: _phase == _Phase.scanning ? const Color(0xFF7C4DFF) : (statusColor == Colors.transparent ? Colors.grey : statusColor),
                      trackColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                      strokeWidth: 18,
                      sweepDegrees: 210,
                      centerChild: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Icon(
                            _phase == _Phase.done ? Icons.security : Icons.phonelink_lock,
                            size: 48,
                            color: _phase == _Phase.scanning ? const Color(0xFF7C4DFF) : (statusColor == Colors.transparent ? Colors.grey : statusColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Status Text
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ).animate(key: ValueKey(_phase)).fadeIn(),
              
              const SizedBox(height: 48),

              // Scan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _phase == _Phase.scanning ? null : _startAudit,
                  icon: _phase == _Phase.scanning 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, color: Colors.white70),
                  label: Text(
                    _phase == _Phase.scanning ? 'Scanning...' : 'Scan Device',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms),

              if (_phase == _Phase.done && _result != null) ...[
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Security Checks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._result!.checks.asMap().entries.map((e) {
                  final c = e.value;
                  final color = c.level == _Level.safe
                      ? const Color(0xFF4CAF50)
                      : c.level == _Level.warning
                          ? const Color(0xFFFFB300)
                          : c.level == _Level.danger
                              ? const Color(0xFFE53935)
                              : const Color(0xFFB71C1C);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B27) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF30363D) : const Color(0xFFE8EEF8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                c.detail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 200 + e.key * 70));
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
enum _Phase { idle, scanning, done }
enum _Level { safe, warning, danger, critical }

class _Check {
  final String label, detail;
  final _Level level;
  final IconData icon;
  const _Check({required this.label, required this.detail, required this.level, required this.icon});
}

class _AuditResult {
  final int score;
  final double rating;
  final List<_Check> checks;
  const _AuditResult({required this.score, required this.rating, required this.checks});
}
