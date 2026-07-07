import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../../data/models/verdict_model.dart';
import '../../core/theme/app_theme.dart';

// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final VerdictModel? verdict;
  final File? image;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.verdict,
    this.image,
  });
}

// State notifier for chat — using Riverpod Notifier
class ChatNotifier extends Notifier<List<ChatMessage>> {
  static const _welcomeMessage = ChatMessage(
    text:
        '🛡️ Namaste! Main SafeSignal Security Shield hoon.\n\nKoi bhi suspicious message, SMS, ya link yahan copy-paste karein — main bata dunga ye Scam hai ya Safe hai.\n\n👇 Aap chat mein screenshot bhi upload kar sakte hain.',
    isUser: false,
  );

  @override
  List<ChatMessage> build() => [_welcomeMessage];

  Future<void> analyzeMessage(String text, {File? image}) async {
    // Add user message
    state = [...state, ChatMessage(text: text, isUser: true, image: image)];

    // Add loading state
    state = [
      ...state,
      const ChatMessage(text: 'Jaanch ho rahi hai...', isUser: false, isLoading: true)
    ];

    // Simulate API call (mock for now)
    await Future.delayed(const Duration(seconds: 2));

    // Simple keyword-based mock routing
    final lower = text.toLowerCase();
    final isScam = lower.contains('arrest') ||
        lower.contains('cbi') ||
        lower.contains('ed ') ||
        lower.contains('paisa bhejo') ||
        lower.contains('won') ||
        lower.contains('prize') ||
        lower.contains('lottery') ||
        lower.contains('suspicious') ||
        lower.contains('lucky draw');

    final isSafe = (lower.contains('otp') && lower.contains('bank')) ||
        lower.contains('your transaction') ||
        lower.contains('credited') ||
        lower.contains('debited');

    final VerdictModel verdict;
    if (isScam) {
      verdict = VerdictModel.mockScam();
    } else if (isSafe) {
      verdict = VerdictModel.mockSafe();
    } else {
      verdict = VerdictModel.mockCaution();
    }

    // Remove loading, add verdict
    state = state.where((m) => !m.isLoading).toList();
    state = [...state, ChatMessage(text: '', isUser: false, verdict: verdict)];
  }

  void clear() {
    state = [_welcomeMessage];
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);
    _controller.clear();
    final img = _selectedImage;
    setState(() => _selectedImage = null);

    await ref.read(chatProvider.notifier).analyzeMessage(
          text.isEmpty ? '[Screenshot Analysis Request]' : text,
          image: img,
        );

    setState(() => _isAnalyzing = false);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGrad,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Chat Shield',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? Colors.white : AppTheme.darkSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.safeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live Protection Active',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(chatProvider.notifier).clear(),
            icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : Colors.black87),
            tooltip: 'Clear chat',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                return _MessageBubble(
                  message: msg,
                  isDark: isDark,
                  onVerdictTap: (v) => context.push('/verdict', extra: v),
                );
              },
            ),
          ),
          
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE8EDF8),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_selectedImage!, height: 50, width: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Screenshot ready to check',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.close, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE8EDF8),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isAnalyzing ? null : _pickImage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    enabled: !_isAnalyzing,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : AppTheme.darkSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Shak wala message yahan paste karein...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF5F7FB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isAnalyzing ? null : _send,
                  child: AnimatedContainer(
                    duration: 200.ms,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isAnalyzing ? null : AppTheme.primaryGrad,
                      color: _isAnalyzing ? (isDark ? Colors.white10 : Colors.grey.shade200) : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isAnalyzing
                          ? []
                          : [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: _isAnalyzing
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final Function(VerdictModel) onVerdictTap;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.onVerdictTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 80),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardAlt : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFEEF2FF),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                message.text,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    if (message.verdict != null) {
      final v = message.verdict!;
      final verdictColor = AppTheme.verdictColor(v.verdict);
      final verdictBg = isDark ? AppTheme.verdictColor(v.verdict).withValues(alpha: 0.1) : AppTheme.verdictBgColor(v.verdict);

      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => onVerdictTap(v),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, right: 40),
            decoration: BoxDecoration(
              color: verdictBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: verdictColor.withValues(alpha: isDark ? 0.35 : 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: verdictColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.verdictGradient(v.verdict),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppTheme.verdictEmoji(v.verdict),
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.verdict == 'SCAM'
                                  ? 'SCAM HAI! 🛑'
                                  : v.verdict == 'LIKELY_SAFE'
                                      ? 'SAFE HAI ✅'
                                      : 'SAVDHAN RAHO ⚠️',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Confidence: ${(v.confidence * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (v.why.isNotEmpty) ...[
                        Text(
                          'KYUN?',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: verdictColor,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...v.why.take(2).map((w) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                      color: verdictColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      w,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Full analysis report dekhein',
                            style: TextStyle(
                              color: verdictColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: verdictColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15),
      );
    }

    // Regular bubble
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 16,
          left: message.isUser ? 60 : 0,
          right: message.isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: message.isUser ? AppTheme.primaryGrad : null,
          color: message.isUser ? null : (isDark ? AppTheme.darkCardAlt : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 20),
          ),
          border: message.isUser
              ? null
              : Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE8EDF8),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(message.image!, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.08),
    );
  }
}
