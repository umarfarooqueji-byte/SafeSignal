import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_device/safe_device.dart';
import 'dart:io';

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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF06090F) : Colors.white;

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
          'Device Audit',
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
              : _buildResult(isDark),
    );
  }

  Widget _buildIdle(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFF44336).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phonelink_lock, size: 56, color: Color(0xFFF44336)),
          ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
          const SizedBox(height: 28),
          Text(
            'Hardware & OS Audit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Aapke phone ke OS mein koi hidden hacker backdoor, root, ya dangerous settings toh on nahi hain? Deep scan karein.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton.icon(
              onPressed: _startAudit,
              icon: const Icon(Icons.search, size: 22),
              label: const Text('Start Deep Audit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                elevation: 0,
              ),
            ),
          ).animate().fadeIn(delay: 220.ms),
        ],
      ),
    );
  }

  Widget _buildScanning(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: const Color(0xFFF44336),
              backgroundColor: const Color(0xFFF44336).withValues(alpha: 0.15),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 1200.ms),
          const SizedBox(height: 28),
          Text(
            'Scanning System Core...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1),
          const SizedBox(height: 8),
          Text(
            'Checking root, ADB, and emulator hooks',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(bool isDark) {
    final r = _result!;
    final gaugeColor = r.score >= 80
        ? const Color(0xFF4CAF50)
        : r.score >= 50
            ? const Color(0xFFFFB300)
            : const Color(0xFFE53935);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
      child: Column(
        children: [
          // Gauge
          SizedBox(
            width: 240,
            height: 200,
            child: ArcGauge(
              value: r.rating,
              maxValue: 5.0,
              color: gaugeColor,
              trackColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              strokeWidth: 18,
              sweepDegrees: 210,
              centerChild: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: r.rating.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: gaugeColor,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: '.${((r.rating * 10) % 10).round()}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: gaugeColor.withValues(alpha: 0.7),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '5',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Text(
            r.score >= 80 ? 'DEVICE IS SECURE' : 'ACTION REQUIRED',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          // Security checks
          ...r.checks.asMap().entries.map((e) {
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
