import 'dart:async';

import 'package:econsultation/core/services/api_service.dart';
import 'package:econsultation/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ApiService _apiService = ApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCodeSent = false;
  bool _isSubmitting = false;
  bool _isResending = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  int _secondsRemaining = 0;
  Timer? _timer;
  String? _error;
  String? _submittedEmail;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
            final logoSize = (maxWidth * 0.22).clamp(64.0, 120.0);
            final ctaHeight = (maxHeight * 0.07).clamp(48.0, 64.0);
            final headerRadius = (maxWidth * 0.06).clamp(16.0, 28.0);

            return SingleChildScrollView(
              child: Column(
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
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          verticalPadding + 12,
                          horizontalPadding,
                          verticalPadding,
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/splash/logo.png',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: maxHeight * 0.02),
                            Text(
                              'Reset Password',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: AppTheme.surface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: maxHeight * 0.01),
                            Text(
                              _isCodeSent
                                  ? 'Enter the code and choose a new password.'
                                  : 'Enter your email to receive a reset code.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.surface,
                              ),
                              textAlign: TextAlign.center,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: maxHeight * 0.02),
                              _buildEmailField(theme),
                              if (_isCodeSent) ...[
                                const SizedBox(height: 16),
                                _buildCodeField(theme),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  theme: theme,
                                  label: 'New Password',
                                  hintText: 'Enter your new password',
                                  controller: _newPasswordController,
                                  showPassword: _showNewPassword,
                                  onToggle: () {
                                    setState(() {
                                      _showNewPassword = !_showNewPassword;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  theme: theme,
                                  label: 'Confirm Password',
                                  hintText: 'Confirm your new password',
                                  controller: _confirmPasswordController,
                                  showPassword: _showConfirmPassword,
                                  onToggle: () {
                                    setState(() {
                                      _showConfirmPassword = !_showConfirmPassword;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _secondsRemaining == 0 && !_isResending
                                        ? _handleResendCode
                                        : null,
                                    child: Text(
                                      _isResending ? 'Resending...' : 'Resend Code',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _secondsRemaining > 0
                                        ? 'Resend in $_secondsRemaining seconds'
                                        : 'You can resend now',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.statusRed,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: ctaHeight,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          if (_isCodeSent) {
                                            _handleResetPassword();
                                          } else {
                                            _handleSendCode();
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
                                    child: Center(
                                      child: _isSubmitting
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
                                              _isCodeSent ? 'Reset Password' : 'Send Code',
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                color: AppTheme.surface,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.go('/'),
                                child: Text(
                                  'Back to Login',
                                  style: theme.textTheme.bodyMedium,
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
          },
        ),
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        TextFormField(
          controller: _emailController,
          readOnly: _isCodeSent,
          keyboardType: TextInputType.emailAddress,
          cursorColor: AppTheme.statusGray,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryText,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.statusGray,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryLight),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) {
              return 'Required field';
            }
            if (!email.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCodeField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verification Code', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          cursorColor: AppTheme.statusGray,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryText,
          ),
          decoration: InputDecoration(
            hintText: 'Enter 6-digit code',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.statusGray,
            ),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryLight),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          validator: (value) {
            if (!_isCodeSent) return null;
            final code = value?.trim() ?? '';
            if (code.isEmpty) {
              return 'Required field';
            }
            if (code.length != 6) {
              return 'Enter 6-digit code';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required ThemeData theme,
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          cursorColor: AppTheme.statusGray,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.statusGray,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryLight),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: AppTheme.secondaryText,
              ),
              onPressed: onToggle,
            ),
          ),
          validator: (value) {
            if (!_isCodeSent) return null;
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Required field';
            }
            if (controller == _newPasswordController && text.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (controller == _confirmPasswordController &&
                text != _newPasswordController.text.trim()) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _handleSendCode() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      final submittedEmail = _emailController.text.trim();
      await _apiService.forgotPassword(email: submittedEmail);

      if (!mounted) return;

      setState(() {
        _submittedEmail = submittedEmail;
        _emailController.text = submittedEmail;
        _isCodeSent = true;
        _isSubmitting = false;
        _secondsRemaining = 59;
        _codeController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      _startTimer();
    } on ApiServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Unable to send reset code right now. Please try again.';
      });
    }
  }

  Future<void> _handleResendCode() async {
    setState(() {
      _error = null;
      _isResending = true;
    });

    try {
      final targetEmail = (_submittedEmail ?? _emailController.text).trim();
      await _apiService.forgotPassword(email: targetEmail);

      if (!mounted) return;

      setState(() {
        _isResending = false;
        _secondsRemaining = 59;
      });
      _startTimer();
    } on ApiServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _error = 'Unable to resend code right now. Please try again.';
      });
    }
  }

  Future<void> _handleResetPassword() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      final targetEmail = (_submittedEmail ?? _emailController.text).trim();
      await _apiService.resetPassword(
        email: targetEmail,
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    } on ApiServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Unable to reset password right now. Please try again.';
      });
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Password Updated'),
          content: Text(
            _submittedEmail == null
                ? 'Your password was changed successfully.'
                : 'Password changed successfully for $_submittedEmail.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                this.context.go('/');
              },
              child: const Text('Back to Login'),
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining == 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }
}
