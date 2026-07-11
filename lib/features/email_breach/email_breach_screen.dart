import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/services/supabase_service.dart';
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

      // Save to Supabase
      try {
        await SupabaseService().saveScanHistory(
          scanType: 'EMAIL',
          target: email,
          status: breaches.isEmpty ? 'SAFE' : 'DANGER',
          details: {
            'breachCount': breaches.length,
            'breachNames': breaches.map((b) => b.title).toList(),
          },
        );
      } catch (e) {
        debugPrint('Supabase save error: $e');
      }

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
    final bg = isDark ? const Color(0xFF06090F) : const Color(0xFFEBF3FA); // Light blue tint matching app theme
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

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
          'Email Guard',
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
              const SizedBox(height: 16),
              
              // Top visual icon (shield/mail)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.mail_solid, size: 50, color: Color(0xFF7C4DFF)),
              ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
              
              const SizedBox(height: 16),
              
              Text(
                _phase == _Phase.idle 
                  ? 'Check for Data Breaches' 
                  : (_phase == _Phase.scanning ? 'Scanning Dark Web...' : 'Scan Complete'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ).animate(key: ValueKey(_phase)).fadeIn(),

              const SizedBox(height: 48),

              // TextField mimicking Scan Link UI
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _phase == _Phase.scanning 
                        ? const Color(0xFF7C4DFF)
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 2,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TextField(
                      controller: _emailCtrl,
                      enabled: _phase != _Phase.scanning,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        prefixIcon: Icon(CupertinoIcons.mail, color: isDark ? Colors.white54 : Colors.black54),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      ),
                      onSubmitted: (_) => _startScan(),
                    ),
                    Positioned(
                      left: 24,
                      top: -10,
                      child: Container(
                        color: bg,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Email',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Enter a valid email address.',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Scan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _phase == _Phase.scanning ? null : _startScan,
                  icon: _phase == _Phase.scanning 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(CupertinoIcons.search, color: Colors.white70),
                  label: Text(
                    _phase == _Phase.scanning ? 'Scanning...' : 'Check Email',
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

              if (_phase == _Phase.error)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Network error. Please check your internet connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              if (_phase == _Phase.done)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: _buildResults(isDark),
                ),
            ],
          ),
        ),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
