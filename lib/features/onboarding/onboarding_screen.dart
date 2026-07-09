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
      gradientColors: [Color(0xFF2979FF), Color(0xFF1565C0)],
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'AI Smart Analysis',
      titleEn: 'AI Smart Analysis',
      desc: 'SCAM / SAFE / SAVDHAN —\nDeep details aur risk levels ke sath.',
      descEn: 'SCAM / SAFE / CAUTION —\nWith deep details and risk metrics.',
      gradientColors: [Color(0xFF7C4DFF), Color(0xFF4527A0)],
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_3.png',
      title: '24/7 Protection',
      titleEn: 'Always Free & Safe',
      desc: 'SMS, call aur background scan se\ncybercrime ko hamesha ke liye rokein.',
      descEn: 'Prevent cyber fraud forever with SMS,\ncall and active background scan.',
      gradientColors: [Color(0xFF00C853), Color(0xFF2E7D32)],
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'Permissions',
      titleEn: 'Why Permissions?',
      desc: 'Hum SMS aur Call logs permission lete hain taki fraud aur scam ko turant rok sakein.\nAapka data aapke phone mein hi rahta hai.',
      descEn: 'We need SMS & Call permissions to scan for fraud and scams in real-time.\nYour data never leaves your device.',
      gradientColors: [Color(0xFFFFB300), Color(0xFFF57F17)],
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(duration: 500.ms, curve: Curves.easeInOutCubic);
    } else {
      context.go('/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use white theme for premium look based on recent request
    const bg = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Dynamic background elements
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: 500.ms,
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _slides[_currentPage].gradientColors[0].withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: AnimatedContainer(
              duration: 500.ms,
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _slides[_currentPage].gradientColors[1].withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _currentPage < _slides.length - 1
                        ? TextButton(
                            onPressed: () => context.go('/language'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : const SizedBox(height: 48),
                  ),
                ),
                
                // Slides
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _slides.length,
                    itemBuilder: (context, i) => _SlideWidget(slide: _slides[i]),
                  ),
                ),

                // Bottom Controls
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (i) => AnimatedContainer(
                            duration: 300.ms,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: _currentPage == i ? 32 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _currentPage == i
                                    ? _slides[_currentPage].gradientColors
                                    : [Colors.grey.shade300, Colors.grey.shade300],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: _currentPage == i
                                  ? [
                                      BoxShadow(
                                        color: _slides[_currentPage].gradientColors[0].withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Premium Action Button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: 400.ms,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _slides[_currentPage].gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _slides[_currentPage].gradientColors[0].withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
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
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
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
        ],
      ),
    );
  }
}

class _SlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;
  
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image Container with Premium Neumorphic/Soft style
        Expanded(
          flex: 55,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              margin: const EdgeInsets.only(top: 20, bottom: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: slide.gradientColors[0].withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: 10,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.contain,
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                ),
              ),
            ),
          ),
        ),
        
        // Text Content
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: slide.gradientColors,
                  ).createShader(bounds),
                  child: Text(
                    slide.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 6),
                
                Text(
                  slide.titleEn,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade400,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 24),
                
                Text(
                  slide.desc,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 8),
                
                Text(
                  slide.descEn,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
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
  final List<Color> gradientColors;

  const _OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.titleEn,
    required this.desc,
    required this.descEn,
    required this.gradientColors,
  });
}
