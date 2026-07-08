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
      imagePath: 'assets/images/onboarding_1.png',
      title: 'Scam Se Bachao',
      titleEn: 'Stay Safe from Scams',
      desc: 'Koi bhi shak wala message bhejein.\nHum use turant check karenge.',
      descEn: 'Forward any suspicious message.\nWe will check it for you.',
      color: Color(0xFF2979FF),
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'AI Smart Analysis',
      titleEn: 'AI Smart Analysis',
      desc: 'SCAM / SAFE / SAVDHAN —\nDeep details aur risk levels ke sath.',
      descEn: 'SCAM / SAFE / CAUTION —\nWith deep details and risk metrics.',
      color: Color(0xFF7C4DFF),
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_3.png',
      title: '24/7 Protection',
      titleEn: 'Always Free & Safe',
      desc: 'SMS, call aur background scan se\ncybercrime ko hamesha ke liye rokein.',
      descEn: 'Prevent cyber fraud forever with SMS,\ncall and active background scan.',
      color: Color(0xFF00C853),
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    } else {
      context.go('/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060A12) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _currentPage < _slides.length - 1
                    ? TextButton(
                        onPressed: () => context.go('/language'),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox(height: 48),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideWidget(slide: _slides[i], isDark: isDark),
              ),
            ),
            // Indicator and Navigation Row
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _slides[_currentPage].color
                              : (isDark ? Colors.white24 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Premium Button
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _slides[_currentPage].color,
                            _slides[_currentPage].color.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _slides[_currentPage].color.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? 'Shuru Karein / Get Started'
                              : 'Aage / Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;
  final bool isDark;
  const _SlideWidget({required this.slide, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1724) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? const Color(0xFF202A3C) : const Color(0xFFEDF2F7),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutCubic),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  slide.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                const SizedBox(height: 4),
                Text(
                  slide.titleEn,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  slide.desc,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                const SizedBox(height: 4),
                Text(
                  slide.descEn,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide {
  final String imagePath;
  final String title;
  final String titleEn;
  final String desc;
  final String descEn;
  final Color color;

  const _OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.titleEn,
    required this.desc,
    required this.descEn,
    required this.color,
  });
}
