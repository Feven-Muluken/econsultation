import 'package:econsultation/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:econsultation/core/services/api_service.dart';
import 'package:econsultation/core/storage/account_profile_storage.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _apiService = ApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isSubmitting = false;
  String? submitError;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Image.asset(
                            'assets/splash/backlogo.png',
                            // 'assets/splash/path2.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
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
                                SizedBox(height: maxHeight * 0.02),
                                Text(
                                  'Create Your Account',
                                  style: theme.textTheme.headlineMedium?.copyWith(
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
                    // padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Column(
                          children: [
                            SizedBox(height: maxHeight * 0.02),
                            // First Name
                            _buildFormField(
                              theme: theme,
                              label: 'First Name',
                              controller: firstNameController,
                              hintText: 'Enter your first name',
                            ),
                            const SizedBox(height: 20),

                            // Last Name
                            _buildFormField(
                              theme: theme,
                              label: 'Middle Name',
                              controller: lastNameController,
                              hintText: 'Enter your middle name',
                            ),
                            const SizedBox(height: 20),

                            // Email
                            _buildFormField(
                              theme: theme,
                              label: 'Email Address',
                              controller: emailController,
                              hintText: 'Enter your email address',
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 20),

                            // Password
                            _buildPasswordField(
                              theme: theme,
                              label: 'Password',
                              controller: passwordController,
                              hintText: 'Enter your password',
                              showPassword: showPassword,
                              onToggle: () {
                                setState(() => showPassword = !showPassword);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password
                            _buildPasswordField(
                              theme: theme,
                              label: 'Confirm Password',
                              controller: confirmPasswordController,
                              hintText: 'Confirm your password',
                              showPassword: showConfirmPassword,
                              onToggle: () {
                                setState(() => showConfirmPassword = !showConfirmPassword);
                              },
                            ),
                            const SizedBox(height: 30),

                            // Info Text
                            Text(
                              "We'll send a verification code to your email\nto complete your registration.",
                              textAlign: TextAlign.center,
                            ),

                            if (submitError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                submitError!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            // Register Button                          
                            const SizedBox(height: 16),
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
                                          submitError = null;
                                          isSubmitting = true;
                                        });
                                        try {
                                          await _apiService.signUp(
                                            firstName: firstNameController.text.trim(),
                                            lastName: lastNameController.text.trim(),
                                            email: emailController.text.trim(),
                                            password: passwordController.text,
                                            middleName: lastNameController.text.trim(),
                                            confirmPassword:
                                                confirmPasswordController.text,
                                          );
                                          await AccountProfileStorage.saveRegisteredProfile(
                                            firstName: firstNameController.text.trim(),
                                            lastName: lastNameController.text.trim(),
                                            email: emailController.text.trim(),
                                          );
                                          if (!mounted) return;
                                          context.go('/register-success');
                                        } on ApiServiceException catch (error) {
                                          if (!mounted) return;
                                          setState(() => submitError = error.message);
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
                                            'Create Your Account',
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            // Sign In Link
                            SizedBox(height: maxHeight * 0.02),
                            Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account?",
                                        style: theme.textTheme.bodyMedium?.copyWith(),
                                      ),                                       TextButton(
                                        onPressed: () => context.go('/'),
                                        child: Text(
                                          'Sign in',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )
            );
          }
        )
      )
    );
  }

  Widget _buildFormField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: AppTheme.primary,
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
          ),
          validator: validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required field';
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
    required TextEditingController controller,
    required String hintText,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          cursorColor: AppTheme.primary,
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
            if (value == null || value.trim().isEmpty) {
              return 'Required field';
            }
            if (controller == confirmPasswordController &&
                value != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required field';
    }
    final email = value.trim();
    final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
