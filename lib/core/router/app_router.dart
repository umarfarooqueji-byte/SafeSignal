import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/language_screen.dart';
import '../../features/onboarding/disclaimer_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/verdict/verdict_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/url_scanner/url_scanner_screen.dart';
import '../../features/wifi_scanner/wifi_scanner_screen.dart';
import '../../features/app_scanner/app_scanner_screen.dart';
import '../../data/models/verdict_model.dart';
import '../constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashRedirectScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/disclaimer',
        builder: (context, state) => const DisclaimerScreen(),
      ),

      // Full-screen tools (outside shell)
      GoRoute(
        path: '/url-scanner',
        builder: (context, state) => const UrlScannerScreen(),
      ),
      GoRoute(
        path: '/wifi-scanner',
        builder: (context, state) => const WifiScannerScreen(),
      ),
      GoRoute(
        path: '/app-scanner',
        builder: (context, state) => const AppScannerScreen(),
      ),
      GoRoute(
        path: '/verdict',
        builder: (context, state) {
          final verdict = state.extra as VerdictModel;
          return VerdictScreen(verdict: verdict);
        },
      ),

      // Shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class SplashRedirectScreen extends StatefulWidget {
  const SplashRedirectScreen({super.key});

  @override
  State<SplashRedirectScreen> createState() => _SplashRedirectScreenState();
}

class _SplashRedirectScreenState extends State<SplashRedirectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.5, end: 1.0));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _controller.forward();
    _redirect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
    if (!mounted) return;
    if (onboardingDone) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.shield_outlined, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'SafeSignal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aapka Digital Suraksha Kawach',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.6),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _routes = ['/home', '/chat', '/feed', '/history', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 65,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          context.go(_routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Check',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
