import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:econsultation/core/theme.dart';

import 'package:econsultation/core/services/mock_auth_api.dart';
import 'package:econsultation/core/storage/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;
  bool isSubmitting = false;
  String? loginError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
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
              // body: SingleChildScrollView(
              child: Column(
                children: [
                  // Header with gradient
                  Container(
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
                        Center(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              verticalPadding + 12,
                              horizontalPadding,
                              verticalPadding,
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
                                  'Welcome Back!',
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    color: AppTheme.surface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: maxHeight * 0.01),
                                Text(
                                  'Sign in to your account',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.surface,
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
                  
                  // Form Section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: maxHeight * 0.02,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SizedBox(height: maxHeight * 0.02),
                              Center(
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Email/Phone',
                                        style: theme.textTheme.labelLarge?.copyWith(),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: emailController,
                                      cursorColor: AppTheme.statusGray,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.primaryText,
                                      ),
                                      // hoverColor: AppTheme.primaryLight.withOpacity(0.08),
                                      // focusColor: AppTheme.primaryLight.withOpacity(0.12),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your email or phone number',
                                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.statusGray,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryLight,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 18,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required field';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Field
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Password',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: !showPassword,
                                      cursorColor: AppTheme.primaryDark,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.primaryText,
                                      ),
                                      // hoverColor: AppTheme.primaryLight.withOpacity(0.08),
                                      // focusColor: AppTheme.primaryLight.withOpacity(0.12),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your password',
                                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.statusGray,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryLight,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 18,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            showPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: AppTheme.secondaryText,
                                          ),
                                          onPressed: () {
                                            setState(() => showPassword = !showPassword);
                                          },
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required field';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          'Forgot password?',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                              if (loginError != null) ...[
                                Text(
                                  loginError!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                              ],
                              SizedBox(
                                width: double.infinity,
                                height: ctaHeight,
                                child: ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          final isValid = _formKey.currentState?.validate() ?? false;
                                          if (!isValid) return;
                                          setState(() {
                                            loginError = null;
                                            isSubmitting = true;
                                          });
                                          try {
                                            final token = await MockAuthApi.instance.login(
                                              email: emailController.text.trim(),
                                              password: passwordController.text,
                                            );
                                            await SecureStorage.writeToken(token);
                                            if (!mounted) return;
                                            context.go('/home');
                                          } on AuthException catch (error) {
                                            if (!mounted) return;
                                            setState(() => loginError = error.message);
                                          } finally {
                                            if (mounted) {
                                              setState(() => isSubmitting = false);
                                            }
                                          }
                                        },
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
                                            child: isSubmitting
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    'Sign In',
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
                              SizedBox(height: maxHeight * 0.02),
                              Center(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: theme.textTheme.bodyMedium?.copyWith(),
                                        ),
                                        TextButton(
                                          onPressed: () => context.go('/register'),
                                          child: Text(
                                            'Register now',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'or',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                        color: AppTheme.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => context.go('/home'),
                                      child: Text(
                                        'Continue as Guest',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.primary,
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
                ],
              ),
            );
          }
        )
      )
    );
  }
}