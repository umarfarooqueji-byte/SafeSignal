import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      emoji: '🛡️',
      title: 'Scam Se Bachao',
      titleEn: 'Stay Safe from Scams',
      desc: 'Koi bhi shak wala message bhejein.\nHum check karenge.',
      descEn: 'Forward any suspicious message.\nWe will check it for you.',
      color: Color(0xFF1565C0),
    ),
    _OnboardingSlide(
      emoji: '⚡',
      title: 'Turant Nateeja',
      titleEn: 'Instant Verdict',
      desc: 'SCAM / SAFE / SAVDHAN —\nKuch hi seconds mein jawab.',
      descEn: 'SCAM / SAFE / CAUTION —\nResult in seconds.',
      color: Color(0xFF388E3C),
    ),
    _OnboardingSlide(
      emoji: '🆓',
      title: 'Bilkul Muft',
      titleEn: 'Always Free',
      desc: 'SafeSignal poori tarah muft hai.\nKoi chupi fees nahi.',
      descEn: 'SafeSignal is completely free.\nNo hidden charges.',
      color: Color(0xFF6A1B9A),
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(duration: 300.ms, curve: Curves.easeInOut);
    } else {
      context.go('/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: 300.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? _slides[_currentPage].color
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _slides[_currentPage].color,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _currentPage == _slides.length - 1 ? 'Shuru Karein / Get Started' : 'Aage / Next',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_currentPage < _slides.length - 1)
              TextButton(
                onPressed: () => context.go('/language'),
                child: const Text('Skip', style: TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(slide.emoji, style: const TextStyle(fontSize: 80)),
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: slide.color,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            slide.titleEn,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          Text(
            slide.desc,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            slide.descEn,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String titleEn;
  final String desc;
  final String descEn;
  final Color color;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.titleEn,
    required this.desc,
    required this.descEn,
    required this.color,
  });
}
