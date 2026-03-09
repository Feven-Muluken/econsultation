import 'package:econsultation/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            final horizontalPadding = (maxWidth * 0.08).clamp(20.0, 36.0);
            final headerRadius = (maxWidth * 0.06).clamp(16.0, 28.0);
            final iconSize = (maxWidth * 0.22).clamp(88.0, 140.0);
            final buttonHeight = (maxHeight * 0.07).clamp(48.0, 60.0);
            final ctaHeight = (maxHeight * 0.07).clamp(48.0, 64.0);

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(headerRadius),
                      bottomRight: Radius.circular(headerRadius),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: (maxHeight * 0.06).clamp(24.0, 48.0),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: iconSize,
                        color: AppTheme.surface,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Registration Successful',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.surface,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account is ready. Please sign in to continue.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.surface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Center(
                  
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  top: 0,
                  right: 0,
                  child: Image.asset(
                    alignment: Alignment.center, 
                    'assets/splash/backlogo.png',
                    // 'assets/splash/path2.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),                  
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: (maxHeight * 0.06).clamp(24.0, 40.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Now You can sign in with your email and password.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: ctaHeight,
                          child: ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (maxWidth * 0.04).clamp(10.0, 16.0),
                                ),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                borderRadius: BorderRadius.circular(
                                  (maxWidth * 0.04).clamp(10.0, 16.0),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding * 0.75,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'Go to Sign In',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: AppTheme.surface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),  
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
