// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key});

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen> {
//   final _otpController = TextEditingController();
//   int _secondsRemaining = 60;

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(seconds: 1), _tick);
//   }

//   void _tick() {
//     if (_secondsRemaining > 0) {
//       setState(() => _secondsRemaining--);
//       Future.delayed(const Duration(seconds: 1), _tick);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Verify OTP")),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           children: [
//             TextFormField(controller: _otpController, decoration: const InputDecoration(labelText: "Enter 6-digit OTP")),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => context.go('/login'),
//               child: const Text("Verify"),
//             ),
//             const SizedBox(height: 20),
//             Text("Resend in $_secondsRemaining seconds"),
//             TextButton(onPressed: () {}, child: const Text("Resend OTP")),
//           ],
//         ),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:econsultation/core/theme.dart';
import 'package:econsultation/core/services/mock_auth_api.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({Key? key}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  int secondsRemaining = 59;
  bool isSubmitting = false;
  String? otpError;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && secondsRemaining > 0) {
        setState(() => secondsRemaining--);
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
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
                            // 'assets/splash/path1.png',
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
                                  'OTP',
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
                      vertical: maxHeight * 0.04,
                    ),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Description
                          Text(
                            'Please enter the 6-digit code sent to your mobile number.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightText,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // OTP Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => _buildOTPField(
                                theme: theme,
                                index: index,
                                controller: otpControllers[index],
                                focusNode: focusNodes[index],
                              ),
                            ),
                          ),
                          if (otpError != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              otpError!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 100),

                          // Verify Button
                          
                          SizedBox(
                            width: double.infinity,
                            height: ctaHeight,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final otp = _collectOtp();
                                      if (otp.length != 6) {
                                        setState(() => otpError = 'Enter the 6-digit code');
                                        return;
                                      }
                                      setState(() {
                                        otpError = null;
                                        isSubmitting = true;
                                      });
                                      try {
                                        await MockAuthApi.instance.verifyOtp(otp: otp);
                                        if (!mounted) return;
                                        context.go('/login');
                                      } on AuthException catch (error) {
                                        if (!mounted) return;
                                        setState(() => otpError = error.message);
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
                                                'Verify',
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
                          const SizedBox(height: 24),

                          // Resend Section
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: secondsRemaining == 0
                                      ? () {
                                          setState(() => secondsRemaining = 59);
                                          _startTimer();
                                        }
                                      : null,
                                  child: TextButton(
                                    onPressed: secondsRemaining == 0
                                        ? () async {
                                            setState(() => otpError = null);
                                            try {
                                              await MockAuthApi.instance.resendOtp();
                                              if (!mounted) return;
                                              setState(() => secondsRemaining = 59);
                                              _startTimer();
                                            } on AuthException catch (error) {
                                              if (!mounted) return;
                                              setState(() => otpError = error.message);
                                            }
                                          }
                                        : null,
                                    child: Text(
                                      'Resend Code',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppTheme.statusGray,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Resend in $secondsRemaining seconds',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        )
      ),
    );
  }

  String _collectOtp() {
    return otpControllers.map((controller) => controller.text.trim()).join();
  }

  Widget _buildOTPField({
    required ThemeData theme,
    required int index,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineLarge?.copyWith(
        ),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.surface),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(focusNodes[index - 1]);
          }
        },
      ),
    );
  }
}
