import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_input_field.dart';
import '../../shared/widgets/gradient_background.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TabController _tabController;
  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _isPhoneCodeSent = false;
  String _fullPhoneNumber = '';
  ResetMethod _currentMethod = ResetMethod.email;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentMethod = _tabController.index == 0 ? ResetMethod.email : ResetMethod.phone;
        _isEmailSent = false;
        _isPhoneCodeSent = false;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: 30),

            // Tab Bar
            _buildTabBar(context),

            const SizedBox(height: 20),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmailResetTab(),
                  _buildPhoneResetTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                Icons.lock_reset,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reset Password',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose how you\'d like to reset your password',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              icon: Icon(Icons.email_outlined),
              text: 'Email',
            ),
            Tab(
              icon: Icon(Icons.phone_outlined),
              text: 'Phone',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailResetTab() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isEmailSent) ...[
                _buildEmailInputSection(),
                const SizedBox(height: 30),
                _buildResetButton(ResetMethod.email),
              ] else ...[
                _buildEmailSentState(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneResetTab() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isPhoneCodeSent) ...[
                _buildPhoneInputSection(),
                const SizedBox(height: 30),
                _buildResetButton(ResetMethod.phone),
              ] else ...[
                _buildPhoneCodeSentState(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInputSection() {
    return Container(
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
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Reset via Email',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: 'Email Address',
            hint: 'Enter your email address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
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
                    'We\'ll send password reset instructions to your email',
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
    );
  }

  Widget _buildPhoneInputSection() {
    return Container(
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
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Reset via Phone',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomPhoneInputField(
            label: 'Phone Number',
            controller: _phoneController,
            hint: 'Enter your phone number',
            onChanged: (phone) {
            _fullPhoneNumber = phone;
            },
            // validator: (value) {
            //   if (value == null || value.isEmpty) {
            //     return 'Please enter your phone number';
            //   }
            //   if (value.length < 9) {
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
                    'We\'ll send you a verification code to reset your password',
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
    );
  }

  Widget _buildResetButton(ResetMethod method) {
    return CustomButton(
      text: _isLoading ? 'Sending...' : method == ResetMethod.email ? 'Send Reset Email' : 'Send Verification Code',
      onPressed: !_isLoading ? () => _handleReset(method) : null,
      isLoading: _isLoading,
      width: double.infinity,
      backgroundColor: Colors.white,
      textColor: AppColors.primaryGreen,
    );
  }

  Widget _buildEmailSentState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
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
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.mark_email_read,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Email Sent!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent password reset instructions to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _emailController.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Check your email and follow the instructions to reset your password.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        CustomButton(
          text: 'Back to Sign In',
          onPressed: () => context.go(AppRoutes.auth),
          variant: ButtonVariant.outlined,
          width: double.infinity,
          textColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildPhoneCodeSentState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
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
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.sms,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Code Sent!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a verification code to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _fullPhoneNumber,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Enter the code on the next screen to verify your identity and reset your password.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleReset(ResetMethod method) async {
    if (!_formKey.currentState!.validate()) return;
    // _fullPhoneNumber = _phoneController.text;
    setState(() => _isLoading = true);

    try {
      final authMethods = ref.read(authMethodsProvider);

      if (method == ResetMethod.email) {
        await authMethods.sendPasswordResetEmail(_emailController.text.trim());
        setState(() {
          _isEmailSent = true;
          _isLoading = false;
        });
      } else {
        // Phone reset method
        await authMethods.verifyPhoneNumber(
          phoneNumber: _fullPhoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) {
            // Auto verification - shouldn't happen for password reset
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() => _isLoading = false);
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
              setState(() {
                _isPhoneCodeSent = true;
                _isLoading = false;
              });

              // Navigate to OTP verification for password reset
              Future.delayed(const Duration(seconds: 2), () {
                context.push(
                  AppRoutes.otpVerification,
                  extra: {
                    'verificationId': verificationId,
                    'phoneNumber': _fullPhoneNumber,
                    'resendToken': resendToken,
                    'isPasswordReset': true, // Flag for password reset flow
                  },
                );
              });
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Handle timeout
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(method == ResetMethod.email
                ? 'Failed to send reset email: $e'
                : 'Failed to send verification code: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

enum ResetMethod {
  email,
  phone,
}