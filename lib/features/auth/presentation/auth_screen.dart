import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_input_field.dart';
import '../../shared/widgets/gradient_background.dart';
import '../providers/auth_provider.dart';
import '../data/repositories/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpUsernameController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  bool _isSignInLoading = false;
  bool _isSignUpLoading = false;
  String _fullPhoneNumber = '';

  bool _requiresPhoneVerification = false;
  String? _incompleteUserId;
  String? _incompletePhoneNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpUsernameController.dispose();
    _signUpPhoneController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showGradient: true,
      animateGradient: false,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildSignInTab(), _buildSignUpTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              'Agrich',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Modern Agricultural Learning Platform',
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

  Widget _buildTabBar() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          padding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            if (_requiresPhoneVerification) _buildPhoneVerificationNotice(),

            CustomInputField(
              label: 'Email',
              hint: 'Enter your email address',
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primaryGreen,
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            CustomInputField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _signInPasswordController,
              obscureText: true,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primaryGreen,
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Sign In',
              onPressed: _handleSignIn,
              isLoading: _isSignInLoading,
              width: double.infinity,
            ),
            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Sign In with Phone',
              variant: ButtonVariant.outlined,
              icon: const Icon(Icons.phone),
              onPressed: _handlePhoneSignIn,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            CustomInputField(
              label: 'Username',
              hint: 'Choose a username',
              controller: _signUpUsernameController,
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.primaryGreen,
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 20),
            CustomInputField(
              label: 'Email',
              hint: 'Enter your email address',
              controller: _signUpEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primaryGreen,
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            CustomPhoneInputField(
              label: 'Phone Number',
              hint: 'Enter phone number',
              controller: _signUpPhoneController,
              onChanged: (phone) {
                _fullPhoneNumber = phone;
              },
              validator: (value) {
                if (value == null || value.number.isEmpty) {
                  return 'Please enter a valid number';
                }
                if (value.number.length < 9) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomInputField(
              label: 'Password',
              hint: 'Create a password',
              controller: _signUpPasswordController,
              obscureText: true,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primaryGreen,
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 20),
            CustomInputField(
              label: 'Confirm Password',
              hint: 'Confirm your password',
              controller: _signUpConfirmPasswordController,
              obscureText: true,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primaryGreen,
              ),
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 20),

            _buildPhoneVerificationInfo(),

            const SizedBox(height: 32),
            CustomButton(
              text: 'Create Account',
              onPressed: _handleSignUp,
              isLoading: _isSignUpLoading,
              width: double.infinity,
            ),
            const SizedBox(height: 16),
            Text(
              'By creating an account, you agree to our Terms of Service and Privacy Policy',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Theme.of(context).dividerColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildPhoneVerificationNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange[300], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phone Verification Required',
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
            'Your account requires phone verification to complete. Please verify your phone number to access all features.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          if (_incompletePhoneNumber != null)
            CustomButton(
              text: 'Verify Phone Number',
              variant: ButtonVariant.outlined,
              onPressed: () => _navigateToPhoneVerification(),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerificationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen.withValues(alpha: 0.3), Colors.green],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phone Verification Required',
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
            'After creating your account, you must verify your phone number to complete the registration process. This ensures account security and enables all features.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _signUpPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() => _isSignInLoading = true);

    try {
      final authRepository = ref.read(authMethodsProvider);
      final identifier = _signInEmailController.text.trim();

      final signInMethod = await authRepository.detectSignInMethod(identifier);

      switch (signInMethod) {
        case SignInMethod.none:
          throw Exception('No account found with this email address');

        case SignInMethod.emailIncomplete:
          setState(() {
            _requiresPhoneVerification = true;
            _incompletePhoneNumber = identifier;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account found but phone verification is required'),
              backgroundColor: Colors.orange,
            ),
          );
          return;

        case SignInMethod.phoneOnly:
          throw Exception(
            'Phone-only accounts are not supported. Please sign up with email.',
          );

        case SignInMethod.email:
        case SignInMethod.phoneLinked:
          await authRepository.signInWithEmailAndPassword(
            identifier,
            _signInPasswordController.text,
          );
          break;

        case SignInMethod.phone:
          _handlePhoneSignIn();
          return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Signed in successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.main);
      }
    } on IncompleteAccountException catch (e) {
      setState(() {
        _requiresPhoneVerification = true;
        _incompleteUserId = e.userId;
        _incompletePhoneNumber = e.phoneNumber;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSignInLoading = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() => _isSignUpLoading = true);

    try {
      final authRepository = ref.read(authMethodsProvider);

      await authRepository.signUpWithEmailAndPassword(
        _signUpEmailController.text.trim(),
        _signUpPasswordController.text.trim(),
        _signUpUsernameController.text.trim(),
        _fullPhoneNumber,
      );

      await _initiatePhoneVerification(_fullPhoneNumber, isSignUp: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSignUpLoading = false);
      }
    }
  }

  Future<void> _initiatePhoneVerification(
    String phoneNumber, {
    required bool isSignUp,
  }) async {

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            if (isSignUp) {
              final authRepository = ref.read(authMethodsProvider);
              await authRepository.linkPhoneCredentialToEmailAccount(
                credential,
              );
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
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phone verification failed: ${e.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            context.push(
              AppRoutes.otpVerification,
              extra: {
                'verificationId': verificationId,
                'phoneNumber': phoneNumber,
                'resendToken': resendToken,
                'isSignUp': isSignUp,
                'verificationType': isSignUp ? 'linkToAccount' : 'signIn',
              },
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout for verification ID: $verificationId');
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
    }
  }

  void _navigateToPhoneVerification() {
    if (_incompletePhoneNumber != null) {
      _initiatePhoneVerification(_incompletePhoneNumber!, isSignUp: false);
    }
  }

  void _handlePhoneSignIn() {
    context.push('/phone-signin');
  }
}
