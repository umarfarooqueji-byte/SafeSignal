import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/alert_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = true;
  String _selectedCategory = 'all';
  String? _errorMessage;

  final _categories = [
    ('all', 'Sab', '📋'),
    ('digital_arrest', 'Arrest Scam', '👮'),
    ('otp', 'OTP Fraud', '🔐'),
    ('investment', 'Investment', '💰'),
    ('lottery', 'Lottery', '🎰'),
    ('general', 'Other Alerts', '⚠️'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final dio = Dio();
      // Google News RSS Search feed for Indian cyber security scams/frauds
      final response = await dio.get<String>(
        'https://news.google.com/rss/search?q=cybersecurity+scam+fraud+india&hl=en-IN&gl=IN&ceid=IN:en',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
          },
        ),
      );

      if (response.data != null && response.data!.contains('<item>')) {
        final parsed = _RssParser.parse(response.data!);
        setState(() {
          _alerts = parsed;
          _loading = false;
        });
      } else {
        throw Exception('Invalid RSS response format');
      }
    } catch (e) {
      // Fallback to mock alerts if network call fails
      setState(() {
        _alerts = AlertModel.mockAlerts();
        _loading = false;
        _errorMessage = 'Online news unavailable. Showing offline alerts.';
      });
    }
  }

  List<AlertModel> get _filtered => _selectedCategory == 'all'
      ? _alerts
      : _alerts.where((a) => a.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF06090F) : const Color(0xFFF0F4FF);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF8A80)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Scam Alerts 🚨',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: textThemeColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchNews,
            icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : Colors.black87),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : (isDark ? const Color(0xFF161B27) : Colors.white),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : (isDark ? const Color(0xFF30363D) : const Color(0xFFE8EEF8)),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE53935).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.$3, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          cat.$2,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87),
                            fontWeight: FontWeight.w800,
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
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade900.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFE53935)),
                        const SizedBox(height: 16),
                        Text(
                          'Google News se scan ho raha hai...',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFE53935),
                    onRefresh: _fetchNews,
                    child: _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📭', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text(
                                  'Is category mein koi alert nahi',
                                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) => _AlertCard(
                              alert: _filtered[i],
                              index: i,
                              isDark: isDark,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final int index;
  final bool isDark;

  const _AlertCard({required this.alert, required this.index, required this.isDark});

  Color get _categoryColor {
    switch (alert.category) {
      case 'digital_arrest':
        return const Color(0xFFD32F2F);
      case 'investment':
        return const Color(0xFFE65100);
      case 'otp':
        return const Color(0xFF1565C0);
      case 'lottery':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF455A64);
    }
  }

  String get _categoryEmoji {
    switch (alert.category) {
      case 'digital_arrest':
        return '👮';
      case 'investment':
        return '💰';
      case 'otp':
        return '🔐';
      case 'lottery':
        return '🎰';
      default:
        return '⚠️';
    }
  }

  String get _categoryLabel {
    switch (alert.category) {
      case 'digital_arrest':
        return 'Arrest Scam';
      case 'investment':
        return 'Investment Fraud';
      case 'otp':
        return 'OTP Fraud';
      case 'lottery':
        return 'Lottery Scam';
      default:
        return 'Safety Update';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return 'Abhi abhi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute pehle';
    if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
    return '${diff.inDays} din pehle';
  }

  Future<void> _openNews() async {
    if (alert.sourceUrl == null) return;
    try {
      final uri = Uri.parse(alert.sourceUrl!);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B27) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE8EEF8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(_categoryEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  _categoryLabel.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                if (alert.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.35,
                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.summary,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: isDark ? Colors.white30 : Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(alert.publishedAt),
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Read More action link
                    InkWell(
                      onTap: _openNews,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Poori News Padhein',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 14, color: color),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40)).slideY(begin: 0.1);
  }
}

// ─── Regex RSS Parser ─────────────────────────────────────────────────────────
class _RssParser {
  static List<AlertModel> parse(String xmlString) {
    final list = <AlertModel>[];
    final itemRegex = RegExp(r'<item>([\s\S]*?)</item>');
    final titleRegex = RegExp(r'<title>([\s\S]*?)</title>');
    final linkRegex = RegExp(r'<link>([\s\S]*?)</link>');
    final dateRegex = RegExp(r'<pubDate>([\s\S]*?)</pubDate>');
    final sourceRegex = RegExp(r'<source[^>]*>([\s\S]*?)</source>');

    final matches = itemRegex.allMatches(xmlString);
    int count = 0;
    for (final match in matches) {
      final itemContent = match.group(1) ?? '';

      final titleMatch = titleRegex.firstMatch(itemContent);
      final linkMatch = linkRegex.firstMatch(itemContent);
      final dateMatch = dateRegex.firstMatch(itemContent);
      final sourceMatch = sourceRegex.firstMatch(itemContent);

      var title = titleMatch?.group(1) ?? 'Scam Alert';
      title = _unescapeXml(title);

      final link = linkMatch?.group(1) ?? '';
      final dateStr = dateMatch?.group(1) ?? '';
      final source = sourceMatch?.group(1) ?? 'Google News';

      DateTime? publishedAt;
      if (dateStr.isNotEmpty) {
        try {
          // Parse typical RFC 822 format (e.g. "Tue, 07 Jul 2026 12:00:00 GMT")
          publishedAt = DateTime.parse(dateStr);
        } catch (_) {}
      }
      publishedAt ??= DateTime.now().subtract(Duration(minutes: count * 20));

      final lowerTitle = title.toLowerCase();
      var category = 'general';
      if (lowerTitle.contains('arrest')) {
        category = 'digital_arrest';
      } else if (lowerTitle.contains('otp') || lowerTitle.contains('sms') || lowerTitle.contains('code') || lowerTitle.contains('sim')) {
        category = 'otp';
      } else if (lowerTitle.contains('invest') || lowerTitle.contains('trading') || lowerTitle.contains('earn') || lowerTitle.contains('money') || lowerTitle.contains('rupees')) {
        category = 'investment';
      } else if (lowerTitle.contains('lottery') || lowerTitle.contains('won') || lowerTitle.contains('prize') || lowerTitle.contains('kbc') || lowerTitle.contains('crore')) {
        category = 'lottery';
      }

      list.add(
        AlertModel(
          id: 'news_${count++}',
          headline: title,
          summary: 'Scam Alert from $source: Be aware and protect yourself. Click the link below to read full online coverage.',
          sourceUrl: link.trim(),
          isTrending: count <= 3,
          publishedAt: publishedAt,
          category: category,
          isNew: count <= 6,
        ),
      );
      if (list.length >= 25) break;
    }
    return list;
  }

  static String _unescapeXml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('<![CDATA[', '')
        .replaceAll(']]>', '');
  }
}
