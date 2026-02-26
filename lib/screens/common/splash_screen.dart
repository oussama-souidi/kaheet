import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/utils/constants.dart';
import 'package:flutter_application_1/config/theme.dart';

/// Splash screen with Kahoot-style animated branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.4)),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _startAnimations();
  }

  void _startAnimations() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _textController.forward();
  }

  void _navigateBasedOnAuth(AuthProvider authProvider) {
    if (_authChecked) return;
    _authChecked = true;

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        if (authProvider.isAuthenticated) {
          if (authProvider.isProfessor) {
            Navigator.of(
              context,
            ).pushReplacementNamed(AppConstants.routeProfessorDashboard);
          } else if (authProvider.isStudent) {
            Navigator.of(
              context,
            ).pushReplacementNamed(AppConstants.routeStudentDashboard);
          }
        } else {
          Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
        }
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!_authChecked &&
            (authProvider.isAuthenticated ||
                authProvider.currentUser == null)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateBasedOnAuth(authProvider);
          });
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Logo
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXXL,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🎯', style: TextStyle(fontSize: 60)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // App name
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Column(
                          children: [
                            Text(
                              'Kaheet',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Real-time quiz battles',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Answer color dots — Kahoot signature
                    FadeTransition(
                      opacity: _textOpacity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _colorDot(AppTheme.answerRed, '▲'),
                          const SizedBox(width: 12),
                          _colorDot(AppTheme.answerBlue, '◆'),
                          const SizedBox(width: 12),
                          _colorDot(AppTheme.answerYellow, '●'),
                          const SizedBox(width: 12),
                          _colorDot(AppTheme.answerGreen, '■'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _colorDot(Color color, String symbol) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
