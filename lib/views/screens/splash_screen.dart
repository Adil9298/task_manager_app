import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Small delay gives the splash screen a polished appearance
    // instead of immediately jumping to the next screen.
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    final authProvider =
    context.read<AuthProvider>();

    await authProvider.checkLogin();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      _navigateTo(
        const HomeScreen(),
      );
    } else {
      _navigateTo(
        const LoginScreen(),
      );
    }
  }


  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
            context,
            animation,
            secondaryAnimation,
            ) {
          return screen;
        },
        transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
            ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration:
        const Duration(milliseconds: 350),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Scaffold(
      backgroundColor:
      theme.colorScheme.surface,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [

              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color:
                  theme.colorScheme.primary,
                  borderRadius:
                  BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset:
                      const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 42,
                  color:
                  theme.colorScheme.onPrimary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Task Manager',
                style: theme
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w700,
                  letterSpacing:
                  -0.4,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Simple. Organized. Productive.',
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                  letterSpacing:
                  0.2,
                ),
              ),

              const SizedBox(height: 44),

              SizedBox(
                width: 24,
                height: 24,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color:
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}