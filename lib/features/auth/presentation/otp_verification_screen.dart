// lib/features/auth/presentation/otp_verification_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/gradient_background.dart';
import '../providers/auth_provider.dart';
import '../data/repositories/auth_repository.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
  final bool isSignUp;
  final String verificationType; // 'linkToAccount', 'signIn', 'passwordReset'

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
    required this.isSignUp,
    required this.verificationType,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  bool _isVerifying = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  String _otpCode = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupTimer();
    _startResendTimer();
  }

  void _setupTimer() {
    _timerController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _timerController, curve: Curves.linear));
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _timerController.reset();
    _timerController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timerController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha:0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primaryGreen.withValues(alpha:0.1),
        border: Border.all(color: AppColors.primaryGreen, width: 2),
      ),
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _handleBackNavigation(),
          ),
          title: const Text(
            'Verify Phone',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 50),
                _buildOtpField(
                  defaultPinTheme,
                  focusedPinTheme,
                  submittedPinTheme,
                ),
                const SizedBox(height: 30),
                _buildVerifyButton(),
                const SizedBox(height: 20),
                _buildResendSection(),
                const SizedBox(height: 30),
                _buildInfoCard(),
                const SizedBox(height: 20),
                if (widget.verificationType == 'linkToAccount')
                  _buildSkipWarning(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.sms, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Verification Code',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha:0.8),
              ),
              children: [
                const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                TextSpan(
                  text: widget.phoneNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(
    PinTheme defaultTheme,
    PinTheme focusedTheme,
    PinTheme submittedTheme,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Pinput(
        length: 6,
        controller: _pinController,
        focusNode: _pinFocusNode,
        defaultPinTheme: defaultTheme,
        focusedPinTheme: focusedTheme,
        submittedPinTheme: submittedTheme,
        separatorBuilder: (index) => const SizedBox(width: 8),
        onChanged: (value) {
          setState(() {
            _otpCode = value;
          });
        },
        onCompleted: (value) {
          _verifyOtp();
        },
        cursor: Container(width: 2, height: 24, color: AppColors.primaryGreen),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: CustomButton(
        text: _isVerifying ? 'Verifying...' : 'Verify Code',
        onPressed: (_isVerifying || _otpCode.length != 6) ? null : _verifyOtp,
        isLoading: _isVerifying,
      ),
    );
  }

  Widget _buildResendSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Text(
            "Didn't receive the code?",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha:0.7),
            ),
          ),
          const SizedBox(height: 8),
          if (_canResend)
            TextButton(
              onPressed: _resendOtp,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha:0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Resend Code'),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Resend in ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha:0.7),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
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
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
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
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white.withValues(alpha:0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Make sure to check your messages and enter the 6-digit code we sent.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha:0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipWarning() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 1000),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha:0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red[300], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verification Required',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Phone verification is mandatory to complete your account setup. Skipping this step will result in account deletion.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha:0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== VERIFICATION LOGIC ====================

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    setState(() => _isVerifying = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);

      switch (widget.verificationType) {
        case 'linkToAccount':
          // Link phone to existing email account (signup completion)
          await authRepository.linkPhoneToEmailAccount(
            widget.phoneNumber,
            widget.verificationId,
            _otpCode,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Account created and verified successfully!',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
              ),
            );
            context.go(AppRoutes.main);
          }
          break;

        case 'signIn':
          // Direct phone sign-in
          await authRepository.signInWithPhoneOTP(
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
          // Phone verification for password reset
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
          // Fallback - determine from context
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            // User is signed in, so this is likely a linking operation
            await authRepository.linkPhoneToEmailAccount(
              widget.phoneNumber,
              widget.verificationId,
              _otpCode,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Phone number verified and linked successfully!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go(AppRoutes.main);
            }
          } else {
            // No user signed in, so this is a sign-in operation
            await authRepository.signInWithPhoneOTP(
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
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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

  Future<void> _resendOtp() async {
    try {
      // Reset timer
      _startResendTimer();

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending new verification code...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Trigger resend using Firebase Auth
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: widget.resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Handle auto-verification
          await _handleAutoVerification(credential);
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New verification code sent!'),
                backgroundColor: AppColors.success,
              ),
            );
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
    }
  }

  Future<void> _handleAutoVerification(PhoneAuthCredential credential) async {
    try {
      final authRepository = ref.read(authRepositoryProvider);

      switch (widget.verificationType) {
        case 'linkToAccount':
          await authRepository.linkPhoneCredentialToEmailAccount(credential);
          break;
        case 'signIn':
          await authRepository.signInWithPhoneCredential(credential);
          break;
        default:
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            await authRepository.linkPhoneCredentialToEmailAccount(credential);
          } else {
            await authRepository.signInWithPhoneCredential(credential);
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

  void _handleBackNavigation() {
    if (widget.verificationType == 'linkToAccount') {
      // Warn user about incomplete account
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Verification?'),
          content: const Text(
            'Going back will cancel your account creation. Your account will be deleted and you\'ll need to start over.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Verification'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Delete the incomplete account
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  try {
                    await user.delete();
                    await ref.read(localStorageServiceProvider).clearUserData();
                  } catch (e) {
                    print('Error deleting incomplete account: $e');
                  }
                }

                if (mounted) {
                  context.go(AppRoutes.auth);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel & Delete'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }
}
