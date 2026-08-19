import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider =
    context.watch<AuthProvider>();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
      theme.colorScheme.surface,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [

                  // -----------------------------------------------------------
                  // BRAND / ICON
                  // -----------------------------------------------------------

                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color:
                        theme.colorScheme.primary,
                        borderRadius:
                        BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: theme
                                .colorScheme
                                .primary
                                .withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 28,
                            offset:
                            const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        size: 40,
                        color: theme
                            .colorScheme
                            .onPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // -----------------------------------------------------------
                  // TITLE
                  // -----------------------------------------------------------

                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: theme
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Sign in to manage your tasks\n'
                        'and stay organized.',
                    textAlign: TextAlign.center,
                    style: theme
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // -----------------------------------------------------------
                  // ERROR MESSAGE
                  // -----------------------------------------------------------

                  if (authProvider.errorMessage !=
                      null) ...[
                    Container(
                      padding:
                      const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme
                            .colorScheme
                            .errorContainer,
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons
                                .error_outline_rounded,
                            color: theme
                                .colorScheme
                                .onErrorContainer,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Text(
                              authProvider
                                  .errorMessage!,
                              style: TextStyle(
                                color: theme
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],

                  // -----------------------------------------------------------
                  // GOOGLE SIGN IN
                  // -----------------------------------------------------------

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                      authProvider.isLoading
                          ? null
                          : () => _signInWithGoogle(
                        context,
                      ),
                      style: ElevatedButton
                          .styleFrom(
                        elevation: 0,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      child:
                      authProvider.isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2.4,
                        ),
                      )
                          : Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .white,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                6,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style:
                                TextStyle(
                                  color:
                                  Colors
                                      .black,
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          const Text(
                            'Continue with Google',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // DIVIDER
                  // -----------------------------------------------------------

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: theme
                              .colorScheme
                              .outlineVariant,
                        ),
                      ),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Text(
                          'OR',
                          style: theme
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight:
                            FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: theme
                              .colorScheme
                              .outlineVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // GUEST LOGIN
                  // -----------------------------------------------------------

                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed:
                      authProvider.isLoading
                          ? null
                          : () => _signInAsGuest(
                        context,
                      ),
                      style: OutlinedButton
                          .styleFrom(
                        elevation: 0,
                        side: BorderSide(
                          color: theme
                              .colorScheme
                              .outline,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .person_outline_rounded,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Continue as Guest',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // -----------------------------------------------------------
                  // GUEST INFORMATION
                  // -----------------------------------------------------------

                  Container(
                    padding:
                    const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(
                        alpha: 0.55,
                      ),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons
                              .info_outline_rounded,
                          size: 20,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Guest tasks are stored for temporary and '
                                'will be removed when you close or log out.',
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GOOGLE LOGIN
  // ---------------------------------------------------------------------------

  Future<void> _signInWithGoogle(
      BuildContext context,
      ) async {
    final authProvider =
    context.read<AuthProvider>();

    final success =
    await authProvider.signInWithGoogle();

    if (!context.mounted) return;

    if (success) {
      _showSuccessSnackBar(
        context,
        'Welcome back!',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
          const HomeScreen(),
        ),
      );

      return;
    }

    _showErrorSnackBar(
      context,
      authProvider.errorMessage ??
          'Unable to sign in with Google.',
    );
  }

  // ---------------------------------------------------------------------------
  // GUEST LOGIN
  // ---------------------------------------------------------------------------

  Future<void> _signInAsGuest(
      BuildContext context,
      ) async {
    final authProvider =
    context.read<AuthProvider>();

    final success =
    await authProvider.signInAsGuest();

    if (!context.mounted) return;

    if (success) {
      _showSuccessSnackBar(
        context,
        'Guest session started.',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
          const HomeScreen(),
        ),
      );

      return;
    }

    _showErrorSnackBar(
      context,
      authProvider.errorMessage ??
          'Unable to continue as guest.',
    );
  }

  // ---------------------------------------------------------------------------
  // SUCCESS SNACKBAR
  // ---------------------------------------------------------------------------

  void _showSuccessSnackBar(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // ERROR SNACKBAR
  // ---------------------------------------------------------------------------

  void _showErrorSnackBar(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }
}