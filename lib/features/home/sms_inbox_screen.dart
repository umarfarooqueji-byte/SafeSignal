import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SmsInboxScreen extends StatefulWidget {
  const SmsInboxScreen({super.key});

  @override
  State<SmsInboxScreen> createState() => _SmsInboxScreenState();
}

class _SmsInboxScreenState extends State<SmsInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SmsRecord> _allSms = [];
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
    _loadSms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('sms_inbox') ?? [];
    final records = jsonList.map((s) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        return SmsRecord.fromJson(m);
      } catch (_) {
        return null;
      }
    }).whereType<SmsRecord>().toList();

    // Sort newest first
    records.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

    setState(() {
      _allSms = records;
      _loading = false;
    });
  }

  List<SmsRecord> get _filtered {
    switch (_tabIndex) {
      case 1:
        return _allSms.where((s) => s.verdict == 'SCAM' || s.verdict == 'CAUTION').toList();
      case 2:
        return _allSms.where((s) => s.verdict == 'SAFE').toList();
      default:
        return _allSms;
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sab Delete Karo?'),
        content: const Text('Saari saved SMS delete ho jaayengi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sms_inbox');
      setState(() => _allSms = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060A12) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : const Color(0xFF0D1117), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SMS Inbox',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
        ),
        centerTitle: false,
        actions: [
          if (_allSms.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: isDark ? Colors.white54 : Colors.black38),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2979FF),
          unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
          indicatorColor: const Color(0xFF2979FF),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: [
            Tab(
              icon: const Icon(Icons.all_inbox_outlined, size: 18),
              text: 'All (${_allSms.length})',
            ),
            Tab(
              icon: const Icon(Icons.warning_amber_outlined, size: 18),
              text: 'Scam (${_allSms.where((s) => s.verdict == 'SCAM' || s.verdict == 'CAUTION').length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              text: 'Safe (${_allSms.where((s) => s.verdict == 'SAFE').length})',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? _buildEmpty(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) => _SmsCard(
                    sms: _filtered[i],
                    isDark: isDark,
                    index: i,
                  ),
                ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 42, color: Color(0xFF2979FF)),
            ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
            const SizedBox(height: 24),
            Text(
              _tabIndex == 0
                  ? 'Abhi Koi SMS Nahi'
                  : _tabIndex == 1
                      ? 'Koi Scam SMS Nahi Mila'
                      : 'Koi Safe SMS Nahi Mila',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Text(
              _tabIndex == 0
                  ? 'Jab bhi koi SMS aayega, SafeSignal automatically analyze karega aur yahan section-wise store karega.'
                  : _tabIndex == 1
                      ? 'Abhi tak koi suspicious ya scam SMS detect nahi hua. Aapka inbox safe hai! ✅'
                      : 'Safe SMS abhi yahan nahi hain.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ).animate().fadeIn(delay: 180.ms),
          ],
        ),
      ),
    );
  }
}

// ─── SMS Card ─────────────────────────────────────────────────────────────────
class _SmsCard extends StatefulWidget {
  final SmsRecord sms;
  final bool isDark;
  final int index;
  const _SmsCard({required this.sms, required this.isDark, required this.index});

  @override
  State<_SmsCard> createState() => _SmsCardState();
}

class _SmsCardState extends State<_SmsCard> {
  bool _expanded = false;

  Color get _verdictColor {
    switch (widget.sms.verdict) {
      case 'SCAM':
        return const Color(0xFFEF5350);
      case 'CAUTION':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String get _verdictEmoji {
    switch (widget.sms.verdict) {
      case 'SCAM':
        return '🔴';
      case 'CAUTION':
        return '⚠️';
      default:
        return '🟢';
    }
  }

  String get _verdictLabel {
    switch (widget.sms.verdict) {
      case 'SCAM':
        return 'SCAM';
      case 'CAUTION':
        return 'SUSPICIOUS';
      default:
        return 'SAFE';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Abhi abhi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m pehle';
    if (diff.inHours < 24) return '${diff.inHours}h pehle';
    if (diff.inDays < 7) return '${diff.inDays}d pehle';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final vc = _verdictColor;
    final sms = widget.sms;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF0F1724) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded
                ? vc.withValues(alpha: 0.5)
                : (widget.isDark
                    ? const Color(0xFF2A3347)
                    : const Color(0xFFE8EEF8)),
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _expanded
                  ? vc.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
              blurRadius: _expanded ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verdict badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: vc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(_verdictEmoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sms.sender,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF0D1117),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: vc.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: vc.withValues(alpha: 0.3),
                                    width: 0.8),
                              ),
                              child: Text(
                                _verdictLabel,
                                style: TextStyle(
                                  color: vc,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sms.body,
                          maxLines: _expanded ? 6 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: widget.isDark
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time_outlined,
                                size: 11,
                                color: widget.isDark
                                    ? Colors.white30
                                    : Colors.black26),
                            const SizedBox(width: 4),
                            Text(
                              _timeAgo(sms.receivedAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.isDark
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                            if (sms.confidence > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.black12,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${sms.confidence}% confidence',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: vc.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Expanded reason
            if (_expanded && sms.reason.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(
                  color: vc.withValues(alpha: 0.05),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(18)),
                  border: Border(
                    top: BorderSide(color: vc.withValues(alpha: 0.15)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      sms.verdict == 'SAFE'
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      color: vc,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sms.reason,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: widget.isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: widget.index * 40)),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────
class SmsRecord {
  final String sender;
  final String body;
  final String verdict; // SAFE | SCAM | CAUTION
  final int confidence;
  final String reason;
  final DateTime receivedAt;

  const SmsRecord({
    required this.sender,
    required this.body,
    required this.verdict,
    required this.confidence,
    required this.reason,
    required this.receivedAt,
  });

  factory SmsRecord.fromJson(Map<String, dynamic> m) => SmsRecord(
        sender: m['sender'] as String? ?? 'Unknown',
        body: m['body'] as String? ?? '',
        verdict: m['verdict'] as String? ?? 'SAFE',
        confidence: m['confidence'] as int? ?? 0,
        reason: m['reason'] as String? ?? '',
        receivedAt: DateTime.tryParse(m['receivedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'body': body,
        'verdict': verdict,
        'confidence': confidence,
        'reason': reason,
        'receivedAt': receivedAt.toIso8601String(),
      };
}
