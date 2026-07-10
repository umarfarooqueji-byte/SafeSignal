import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/hibp_service.dart';
import '../../core/services/llm_orchestrator.dart';

class EmailBreachScreen extends StatefulWidget {
  const EmailBreachScreen({super.key});

  @override
  State<EmailBreachScreen> createState() => _EmailBreachScreenState();
}

class _EmailBreachScreenState extends State<EmailBreachScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final HibpService _hibp = HibpService();
  
  _Phase _phase = _Phase.idle;
  List<BreachInfo> _breaches = [];
  String _verdict = '';

  Future<void> _startScan() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _phase = _Phase.scanning;
      _breaches.clear();
      _verdict = '';
    });

    try {
      final breaches = await _hibp.checkEmail(email);
      
      // Calculate risk score based on what was leaked
      int score = 0;
      for (var b in breaches) {
        if (b.dataClasses.contains('Passwords')) score += 40;
        if (b.dataClasses.contains('Email addresses')) score += 10;
        if (b.dataClasses.contains('Phone numbers')) score += 20;
        if (b.dataClasses.contains('Physical addresses')) score += 20;
      }
      score = score.clamp(0, 100);

      setState(() {
        _breaches = breaches;
        _phase = _Phase.done;
      });

      // Fetch LLM Verdict
      _fetchVerdict(email, breaches);

    } catch (e) {
      setState(() => _phase = _Phase.error);
    }
  }

  Future<void> _fetchVerdict(String email, List<BreachInfo> breaches) async {
    if (breaches.isEmpty) {
      setState(() => _verdict = 'Great news! Your email "$email" has not been found in any public data breaches.');
      return;
    }

    final prompt = '''
    Analyze these data breaches for the email $email.
    Breaches: ${breaches.map((b) => '${b.title} (Leaked: ${b.dataClasses.join(", ")})').join(' | ')}
    
    Give a concise, authoritative security verdict in 2-3 sentences. Tell the user exactly what to do (e.g., change passwords immediately, enable 2FA). Use simple English/Hinglish. Do NOT use markdown.
    ''';

    try {
      final verdictObj = await LlmOrchestrator().analyze(text: prompt, type: 'chat');
      if (mounted) {
        setState(() => _verdict = verdictObj.summary);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _verdict = 'WARNING: Your email was found in ${breaches.length} data breaches. Please change your passwords for the affected services immediately and enable Two-Factor Authentication.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF06090F) : const Color(0xFFF8F9FB);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Email Guard',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: textColor),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          Expanded(
            child: _phase == _Phase.idle
                ? _buildIdle(isDark)
                : _phase == _Phase.scanning
                    ? _buildScanning(isDark)
                    : _phase == _Phase.error
                        ? _buildError(isDark)
                        : _buildResults(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter your email address...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: Icon(CupertinoIcons.mail, color: isDark ? Colors.white54 : Colors.black54),
                filled: true,
                fillColor: isDark ? const Color(0xFF161B27) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _startScan(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _startScan,
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(CupertinoIcons.search, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.globe, size: 50, color: Color(0xFF7C4DFF)),
          ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
          const SizedBox(height: 24),
          Text(
            'Dark Web Scanner',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Check karein ki aapka password ya data kisi company ke hack (zomato, facebook) mein chori toh nahi hua.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ).animate().fadeIn(delay: 150.ms),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120, height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: const Color(0xFF7C4DFF),
                    backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  ),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
                const Icon(CupertinoIcons.shield_slash, color: Color(0xFF7C4DFF), size: 40)
                    .animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Scanning Dark Web...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1),
          const SizedBox(height: 8),
          Text(
            'Searching billions of leaked records',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Text('An error occurred. Please check your internet connection.', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_breaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF10B981)).animate().scale().fadeIn(),
            const SizedBox(height: 20),
            Text(
              'No Breaches Found!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              'Aapka email secure hai. Kisi leak mein nahi mila.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      children: [
        // AI Verdict Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFA370F7), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Security Analyst',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _verdict.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA370F7)))
                  : Text(
                      _verdict,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(),
            ],
          ),
        ).animate().slideY(begin: 0.1).fadeIn(),
        const SizedBox(height: 30),

        // Breaches List
        Text(
          'FOUND IN ${_breaches.length} BREACHES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : Colors.black38,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),

        ..._breaches.map((b) {
          final hasPwd = b.dataClasses.contains('Passwords');
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B27) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            b.logoPath,
                            errorBuilder: (c, e, s) => const Icon(Icons.business, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Breached on ${b.breachDate}',
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (hasPwd)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'PWD LEAKED',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compromised Data:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: b.dataClasses.map((dc) {
                          final isPwd = dc == 'Passwords';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? (isPwd ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF2A3347)) : (isPwd ? const Color(0xFFEF4444).withValues(alpha: 0.1) : Colors.white),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isPwd ? const Color(0xFFEF4444).withValues(alpha: 0.3) : (isDark ? const Color(0xFF3B4457) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPwd ? CupertinoIcons.lock_fill : CupertinoIcons.doc_text_fill,
                                  size: 12,
                                  color: isPwd ? const Color(0xFFEF4444) : (isDark ? Colors.white54 : Colors.black54),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dc,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isPwd ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
        }),
      ],
    );
  }
}

enum _Phase { idle, scanning, done, error }
