import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_input_field.dart';
import '../../shared/widgets/gradient_background.dart';
import '../providers/auth_provider.dart';

class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _fullPhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              const SizedBox(height: 40),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Phone Input Section
                        _buildPhoneInputSection(context),

                        const SizedBox(height: 40),

                        // Continue Button
                        _buildContinueButton(context),

                        const SizedBox(height: 30),

                        // Or Divider
                        _buildDivider(),

                        const SizedBox(height: 30),

                        // Sign In with Email Button
                        _buildEmailSignInButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.phone_android,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sign In with Phone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your phone number to receive a verification code',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputSection(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone Number',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            CustomPhoneInputField(
              controller: _phoneController,
              hint: 'Enter your phone number',
              onChanged: (phone) {
                setState(() {
                  _fullPhoneNumber = phone;
                });
                print(_fullPhoneNumber);
              },
              // validator: (value) {
              //   if (value == null || value.isEmpty) {
              //     return 'Please enter your phone number';
              //   }
              //   if (value.completeNumber.length < 9) {
              //     return 'Phone number must be at least 9 digits';
              //   }
              //   return null;
              // },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We\'ll send you a verification code via SMS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: CustomButton(
        text: _isLoading ? 'Sending Code...' : 'Continue',
        onPressed: _fullPhoneNumber.length > 7 && !_isLoading ? _handleContinue : null,
        isLoading: _isLoading,
        width: double.infinity,

      ),
    );
  }

  Widget _buildDivider() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 500),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).dividerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSignInButton(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 600),
      child: CustomButton(
        text: 'Sign In with Email',
        onPressed: () => context.pop(), // Go back to main auth screen
        variant: ButtonVariant.outlined,
        width: double.infinity,
        // textColor: Colors.white,
        icon: const Icon(Icons.email_outlined),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // _fullPhoneNumber = _phoneController.text;
      final authMethods = ref.read(authMethodsProvider);

      await authMethods.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification completed
          try {
            await authMethods.signInWithPhoneCredential(credential);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number verified automatically!'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go(AppRoutes.main);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sign in failed: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification failed: ${e.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            // Navigate to OTP verification screen
            context.push(
              AppRoutes.otpVerification,
              extra: {
                'verificationId': verificationId,
                'phoneNumber': _fullPhoneNumber,
                'resendToken': resendToken,
                'isSignIn': true, // Flag to indicate this is sign-in, not sign-up
              },
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
            content: Text('Failed to send verification code: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}