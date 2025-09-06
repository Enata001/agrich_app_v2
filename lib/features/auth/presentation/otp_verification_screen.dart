import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/gradient_background.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String? verificationType; // 🔥 NEW: Add verification type parameter

  const OtpVerificationScreen({
  super.key,
  required this.phoneNumber,
  required this.verificationId,
    this.verificationType,
  });
  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  bool _isVerifying = false;
  int _resendCountdown = 60;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _setupTimer();
    _startCountdown();
  }

  void _setupTimer() {
    _timerController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    );
  }

  void _startCountdown() {
    _timerController.forward();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primaryGreen, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primaryGreen, width: 2),
      ),
    );

    return CustomScaffold(
      showGradient: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Header
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.sms,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verification Code',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a verification code to\n'),
                          TextSpan(
                            text: widget.phoneNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // PIN Input
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  separatorBuilder: (index) => const SizedBox(width: 8),
                  onChanged: (value) {
                    setState(() {
                      _otpCode = value;
                    });
                  },
                  onCompleted: (value) {
                    _verifyOtp();
                  },
                  cursor: Container(
                    width: 2,
                    height: 24,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Verify Button
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: CustomButton(
                  text: 'Verify Code',
                  onPressed: _otpCode.length == 6 ? _verifyOtp : null,
                  isLoading: _isVerifying,
                  width: double.infinity,
                ),
              ),

              const SizedBox(height: 40),

              // Resend Section
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    if (_resendCountdown > 0) ...[
                      Text(
                        'Didn\'t receive the code?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Resend in ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_resendCountdown}s',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress indicator
                      Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: AnimatedBuilder(
                          animation: _timerAnimation,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _timerAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Didn\'t receive the code?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _resendOtp,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Resend Code'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Help text
              FadeIn(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Make sure to check your messages and enter the 6-digit code we sent.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    setState(() => _isVerifying = true);

    try {
      final authMethods = ref.read(authMethodsProvider);

      // 🔥 FIXED: Handle different verification types
      switch (widget.verificationType) {
        case 'linkToAccount':
        // Link phone to existing email account
          await authMethods.linkPhoneToEmailAccount(
            widget.phoneNumber,
            widget.verificationId,
            _otpCode,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone number linked successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go(AppRoutes.main);
          }
          break;

        case 'signIn':
        // Direct phone sign-in
          await authMethods.signInWithPhoneOTP(
            widget.phoneNumber,
            widget.verificationId,
            _otpCode,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signed in successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go(AppRoutes.main);
          }
          break;

        case 'passwordReset':

          await authMethods.signInWithPhoneOTP(
            widget.phoneNumber,
            widget.verificationId,
            _otpCode,
          );

          if (mounted) {
            context.pushReplacement(
              AppRoutes.newPassword,
              extra: {
                'phoneNumber': widget.phoneNumber,
                'verificationId': widget.verificationId,
                'verifiedOtp': _otpCode,
              },
            );
          }
          break;

        default:
        // Default behavior - try to determine from context
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            // User is signed in, so this is likely a linking operation
            await authMethods.linkPhoneToEmailAccount(
              widget.phoneNumber,
              widget.verificationId,
              _otpCode,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number linked successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go(AppRoutes.main);
            }
          } else {
            // No user signed in, so this is a sign-in operation
            await authMethods.signInWithPhoneOTP(
              widget.phoneNumber,
              widget.verificationId,
              _otpCode,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed in successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go(AppRoutes.main);
            }
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );

        // Clear the PIN field on error
        _pinController.clear();
        setState(() {
          _otpCode = '';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  // 🔥 FIXED: Resend OTP with proper phone number
  Future<void> _resendOtp() async {
    setState(() => _isVerifying = true);

    try {
      final authMethods = ref.read(authMethodsProvider);

      await authMethods.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Handle auto-verification if it happens again
          _handleAutoVerification(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to resend code: ${e.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            // Update the verification ID
            setState(() {
              // You might need to update the verification ID here
              // This would require making verificationId mutable
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New verification code sent!'),
                backgroundColor: AppColors.success,
              ),
            );

            // Restart the countdown
            _startCountdown();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend code: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  // 🔥 NEW: Handle auto-verification during resend
  Future<void> _handleAutoVerification(PhoneAuthCredential credential) async {
    try {
      final authMethods = ref.read(authMethodsProvider);

      switch (widget.verificationType) {
        case 'linkToAccount':
          await authMethods.linkPhoneCredentialToEmailAccount(credential);
          break;
        case 'signIn':
          await authMethods.signInWithPhoneCredential(credential);
          break;
        default:
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            await authMethods.linkPhoneCredentialToEmailAccount(credential);
          } else {
            await authMethods.signInWithPhoneCredential(credential);
          }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verified automatically!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.main);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-verification failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}