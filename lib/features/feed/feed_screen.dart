import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/alert_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late List<AlertModel> _alerts;
  bool _loading = false;
  String _selectedCategory = 'all';

  final _categories = [
    ('all', 'Sab', '📋'),
    ('digital_arrest', 'Arrest Scam', '👮'),
    ('otp', 'OTP Fraud', '🔐'),
    ('investment', 'Investment', '💰'),
    ('lottery', 'Lottery', '🎰'),
  ];

  @override
  void initState() {
    super.initState();
    _alerts = AlertModel.mockAlerts();
  }

  List<AlertModel> get _filtered => _selectedCategory == 'all'
      ? _alerts
      : _alerts.where((a) => a.category == _selectedCategory).toList();

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _alerts = AlertModel.mockAlerts();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scam Alerts 🚨', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.$3, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          cat.$2,
                          style: TextStyle(
                            color: isSelected ? Colors.white : cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📭', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'Is category mein koi alert nahi',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) =>
                          _AlertCard(alert: _filtered[i], index: i),
                    ),
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final int index;

  const _AlertCard({required this.alert, required this.index});

  Color get _categoryColor {
    switch (alert.category) {
      case 'digital_arrest': return const Color(0xFFD32F2F);
      case 'investment': return const Color(0xFFE65100);
      case 'otp': return const Color(0xFF1565C0);
      case 'lottery': return const Color(0xFF6A1B9A);
      default: return const Color(0xFF37474F);
    }
  }

  String get _categoryEmoji {
    switch (alert.category) {
      case 'digital_arrest': return '👮';
      case 'investment': return '💰';
      case 'otp': return '🔐';
      case 'lottery': return '🎰';
      default: return '⚠️';
    }
  }

  String get _categoryLabel {
    switch (alert.category) {
      case 'digital_arrest': return 'Arrest Scam';
      case 'investment': return 'Investment Fraud';
      case 'otp': return 'OTP Fraud';
      case 'lottery': return 'Lottery Scam';
      default: return 'Alert';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute pehle';
    if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
    return '${diff.inDays} din pehle';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF161B22)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored top banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _categoryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Text(_categoryEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  _categoryLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (alert.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                if (alert.isTrending) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 11, color: Colors.white),
                        SizedBox(width: 2),
                        Text('TREND',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.headline,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.summary,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(alert.publishedAt),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 16, color: _categoryColor),
                          const SizedBox(width: 4),
                          Text('Share',
                              style: TextStyle(
                                  color: _categoryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideY(begin: 0.15);
  }
}
