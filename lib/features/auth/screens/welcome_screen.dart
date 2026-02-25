// lib/features/auth/presentation/welcome_screen.dart
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:intl/intl.dart';  // For localization, assume S is from l10n

// class WelcomeScreen extends ConsumerWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: theme.colorScheme.background,
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // MInT Logo with Amharic text
//                 Image.asset(
//                   'assets/images/mint_logo.png',
//                   height: 120,  // Adjust based on your asset size
//                 ),
//                 const SizedBox(height: 16),
//                 // App Title - Using Heading 1 Bold
//                 Text(
//                   'Your Voice in Law!',  // From sprints
//                   style: theme.textTheme.displayLarge,
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 // Subtitle - Using Body Large Medium, from SRS intro
//                 Text(
//                   'Enhance citizen participation and government transparency by providing easy access to draft legal documents and a direct channel to submit valuable feedback.',
//                   // style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 48),
//                 // CTA Button: Create Account - ElevatedButton primary
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () => context.go('/register'),
//                     child: const Text('Create Account'),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Continue as Guest - OutlinedButton or TextButton
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () => context.go('/documents'),  // Guest to documents list per UR-001
//                     child: const Text('Continue as Guest'),
//                   ),
//                 ),
//                 const SizedBox(height: 64),
//                 // 360Ground Logo at bottom
//                 Image.asset(
//                   'assets/images/360ground_logo.png',
//                   height: 60,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const FlutterLogo(size: 120),
//             const SizedBox(height: 20),
//             Text("Your Voice in Law!", style: Theme.of(context).textTheme.displayMedium),
//             const SizedBox(height: 10),
//             Text("Engage with draft laws and share feedback.", style: Theme.of(context).textTheme.bodyMedium),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: () => context.go('/register'),
//               child: const Text("Create Account"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLocalizations.of(context)!;

//     return Scaffold(
//       body: Center(
//         child: Column(
//           children: [
//             Text(loc.welcomeTitle, style: Theme.of(context).textTheme.displayMedium),
//             Text(loc.welcomeSubtitle, style: Theme.of(context).textTheme.bodyMedium),
//             ElevatedButton(
//               onPressed: () {},
//               child: Text(loc.registerButton),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:econsultation/core/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
            final horizontalPadding = (maxWidth * 0.06).clamp(16.0, 32.0);
            final verticalPadding = (maxHeight * 0.03).clamp(16.0, 32.0);
            final contentMaxWidth = maxWidth > 560 ? 560.0 : maxWidth;
            final headerHeight = maxHeight * 0.5;
            final logoSize = (maxWidth * 0.22).clamp(64.0, 120.0);
            final illustrationHeight = (maxHeight * 0.28).clamp(180.0, 260.0);
            final illustrationOverlap = illustrationHeight * 0.35;
            final ctaHeight = (maxHeight * 0.07).clamp(48.0, 64.0);
            final headerRadius = (maxWidth * 0.06).clamp(16.0, 28.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: maxHeight),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        Container(
                          height: headerHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(headerRadius),
                              bottomRight: Radius.circular(headerRadius),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Positioned.fill(
                              //   bottom: 0,
                              //   left: -150,
                              //   child: Image.asset(
                              //     '../../../../assets/splash/path1.png',
                              //     // '../../../../assets/splash/path2.png',
                              //     width: 100,
                              //     height: 100,
                              //     fit: BoxFit.contain,
                              //   ),
                              // ),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: verticalPadding,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/splash/logo.png',
                                        width: logoSize,
                                        height: logoSize,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(height: maxHeight * 0.02),
                                      Text(
                                        'Your Voice In Law!',
                                        style: theme.textTheme.displayLarge?.copyWith(
                                          color: AppTheme.surface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: maxHeight * 0.01),
                                      Text(
                                        'Create your account',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.background,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: illustrationHeight - illustrationOverlap + maxHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: maxHeight * 0.03,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: contentMaxWidth),
                              child: Column(
                                children: [
                                  Text(
                                    'To E-Consult Connect. Your trusted source for\n'
                                    'government proclamations and updates.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: maxHeight * 0.02,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: contentMaxWidth),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: ctaHeight,
                                    child: ElevatedButton(
                                      onPressed: () => context.go('/register'),
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
                                                  'Create Your Account',
                                                  textAlign: TextAlign.center,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: (maxWidth * 0.05).clamp(18.0, 24.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: maxHeight * 0.02),
                                  TextButton(
                                    onPressed: () => context.go('/home'),
                                    child: Text(
                                      'Continue as Guest',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.primary,
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
                    Positioned(
                      left: 0,
                      right: 0,
                      top: headerHeight - illustrationOverlap,
                      child: Center(
                        child: SizedBox(
                          height: illustrationHeight,
                          child: Image.asset(
                            'assets/splash/card.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// class StarPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.1)
//       ..strokeWidth = 2;

//     // Draw decorative star pattern based on available size
//     final first = Offset(size.width * 0.2, size.height * 0.25);
//     final second = Offset(size.width * 0.75, size.height * 0.35);
//     final third = Offset(size.width * 0.45, size.height * 0.7);

//     canvas.drawCircle(first, size.shortestSide * 0.08, paint);
//     canvas.drawCircle(second, size.shortestSide * 0.06, paint);
//     canvas.drawCircle(third, size.shortestSide * 0.1, paint);
//   }

//   @override
//   bool shouldRepaint(StarPatternPainter oldDelegate) => false;
// }







 // body: SafeArea(
      //   child: Padding(
      //     padding: const EdgeInsets.symmetric(horizontal: 24.0),
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         // Logo
      //         Image.asset(
      //           '../../../../assets/splash/Y',
      //           width: 120,
      //           height: 120,
      //         ),
      //         // const FlutterLogo(size: 120), // Replace with your app logo asset
      //         const SizedBox(height: 32),

      //         // Title
      //         Text(
      //           "Welcome Back!",
      //           style: Theme.of(context).textTheme.displayMedium,
      //           textAlign: TextAlign.center,
      //         ),
      //         const SizedBox(height: 8),

      //         // Subtitle
      //         Text(
      //           "Sign in to your account",
      //           style: Theme.of(context).textTheme.bodyMedium,
      //           textAlign: TextAlign.center,
      //         ),
      //         const SizedBox(height: 40),

      //         // CTA Button → Register
      //         ElevatedButton(
      //           onPressed: () => context.go('/register'),
      //           style: ElevatedButton.styleFrom(
      //             minimumSize: const Size(double.infinity, 48),
      //           ),
      //           child: const Text("Create Account"),
      //         ),
      //         const SizedBox(height: 16),

      //         // Secondary CTA → Login
      //         OutlinedButton(
      //           onPressed: () => context.go('/login'),
      //           style: OutlinedButton.styleFrom(
      //             minimumSize: const Size(double.infinity, 48),
      //           ),
      //           child: const Text("Login"),
      //         ),

      //         const SizedBox(height: 16),

      //         // Continue as Guest
      //         TextButton(
      //           onPressed: () => context.go('/home'),
      //           child: const Text("Continue as Guest"),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),