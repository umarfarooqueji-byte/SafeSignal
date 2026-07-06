import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Mock history data
  final List<Map<String, dynamic>> _history = [
    {
      'text': 'CBI case hai, paisa bhejo warna arrest',
      'verdict': 'SCAM',
      'confidence': 0.94,
      'time': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'text': 'Your OTP is 123456 for SBI transaction',
      'verdict': 'LIKELY_SAFE',
      'confidence': 0.88,
      'time': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'text': 'Congratulations! You won 50000 rupees lottery',
      'verdict': 'UNCERTAIN',
      'confidence': 0.65,
      'time': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meri Jaanchein', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📋', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('Abhi tak koi jaanch nahi.\nMessage bhejkar shuru karein.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, i) {
                final item = _history[i];
                final color = AppTheme.verdictColor(item['verdict']);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.verdictBgColor(item['verdict']),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(AppTheme.verdictEmoji(item['verdict']), style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    title: Text(
                      item['text'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              item['verdict'],
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(item['time']),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to verdict detail (Step 10: load from Hive)
                    },
                  ),
                );
              },
            ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
