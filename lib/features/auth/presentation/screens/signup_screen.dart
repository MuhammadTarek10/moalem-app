import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/buttons.dart';
import 'package:moalem/shared/widgets/hyperlinks.dart';
import 'package:moalem/shared/widgets/inputs.dart';

import '../controllers/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _confirmPasswordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authControllerProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            context.go(AppRoutes.home); // Navigate to home on success
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),
                  // Logo
                  Image.asset(
                    AppAssets.images.logo,
                    height: 120.h,
                    width: 120.w,
                  ),
                  SizedBox(height: 40.h),
                  // Title
                  Text(
                    AppStrings.signUpTitle.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  // Email Field
                  InputLabel(label: AppStrings.emailLabel.tr()),
                  SizedBox(height: 8.h),
                  AppTextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    label: AppStrings.emailLabel.tr(),
                    hint: AppStrings.emailHint.tr(),
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: emailValidator,
                  ),
                  SizedBox(height: 16.h),
                  // Password Field
                  InputLabel(label: AppStrings.passwordLabel.tr()),
                  SizedBox(height: 8.h),
                  AppTextFormField(
                    controller: _passwordController,
                    hint: AppStrings.passwordLabel.tr(),
                    obscureText: !_isPasswordVisible,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: SvgPicture.asset(
                        _isPasswordVisible
                            ? AppAssets.icons.passwordVisible
                            : AppAssets.icons.passwordInviable,
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: passwordValidator,
                  ),
                  SizedBox(height: 16.h),
                  // Confirm Password Field
                  InputLabel(label: AppStrings.confirmPasswordLabel.tr()),
                  SizedBox(height: 8.h),
                  AppTextFormField(
                    controller: _confirmPasswordController,
                    hint: AppStrings.confirmPasswordHint.tr(),
                    obscureText: !_isPasswordVisible,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: SvgPicture.asset(
                        _isPasswordVisible
                            ? AppAssets.icons.passwordVisible
                            : AppAssets.icons.passwordInviable,
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) => confirmPasswordValidator(
                      value,
                      _passwordController.text.trim(),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Sign Up Button
                  AppButton(
                    text: AppStrings.signUpButton.tr(),
                    onPressed: _onSignUp,
                    isLoading: isLoading,
                  ),
                  SizedBox(height: 24.h),
                  // Sign In Link
                  TextAndLink(
                    text: AppStrings.haveAccountPrompt.tr(),
                    link: AppRoutes.signIn,
                    hyperLinkText: AppStrings.signInLink.tr(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
