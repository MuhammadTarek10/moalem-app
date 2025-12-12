import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/auth/presentation/controllers/auth_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/buttons.dart';
import 'package:moalem/shared/widgets/hyperlinks.dart';
import 'package:moalem/shared/widgets/inputs.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authControllerProvider, (previous, next) {
      next.when(
        data: (tokens) {
          if (tokens != null) {
            context.go(AppRoutes.home);
          }
        },
        error: (error, stack) {
          context.showTextSnackBar(error.toString());
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
                    height: 160.h,
                    width: 160.w,
                  ),
                  SizedBox(height: 20.h),
                  // Title
                  Text(
                    AppStrings.signInTitle.tr(),
                    textAlign: TextAlign.center,
                    style: context.headlineSmall.copyWith(color: Colors.black),
                  ),
                  SizedBox(height: 8.h),
                  // Description
                  Text(
                    AppStrings.signInDescription.tr(),
                    textAlign: TextAlign.center,
                    style: context.bodySmall.copyWith(
                      color: AppColors.textSubtitle,
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
                  SizedBox(height: 20.h),
                  // Password Field
                  InputLabel(label: AppStrings.passwordLabel.tr()),
                  SizedBox(height: 8.h),
                  AppTextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    hint: AppStrings.passwordHint.tr(),
                    validator: passwordValidator,
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
                  ),
                  SizedBox(height: 12.h),
                  // Remember Me & Forgot Password
                  Row(
                    children: [
                      // Checkbox
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Text(
                        AppStrings.rememberMe.tr(),
                        style: context.bodySmall,
                      ),
                      const Spacer(),
                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          // Navigate to forgot password
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.forgotPassword.tr(),
                          style: context.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  // Sign In Button
                  AppButton(
                    text: AppStrings.signInButton.tr(),
                    onPressed: _onSignIn,
                    isLoading: isLoading,
                  ),
                  SizedBox(height: 24.h),
                  // Sign Up Link
                  TextAndLink(
                    text: AppStrings.signUpPrompt.tr(),
                    link: AppRoutes.signUp,
                    hyperLinkText: AppStrings.signUpLink.tr(),
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
