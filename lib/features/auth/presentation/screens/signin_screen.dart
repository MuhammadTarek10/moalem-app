import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/core/utils/license_checker.dart';
import 'package:moalem/features/auth/presentation/controllers/auth_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/app_button.dart';
import 'package:moalem/shared/widgets/hyperlinks.dart';
import 'package:moalem/shared/widgets/text_input.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  void _onSignIn() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .signIn(_email.trim(), _password);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authControllerProvider, (previous, next) {
      next.when(
        data: (tokens) {
          if (tokens != null) {
            final storage = getIt<StorageService>();
            final licenseExpiresAt = storage.getString(
              AppKeys.licenseExpiresAt,
            );
            if (LicenseChecker.isLicenseValid(licenseExpiresAt)) {
              context.go(AppRoutes.home);
            } else {
              context.go(AppRoutes.activation);
            }
          }
        },
        error: (error, stack) {
          context.showErrorSnackBar(ErrorHandler.getErrorMessage(error));
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
                  // Logo
                  Image.asset(
                    AppAssets.images.logo,
                    height: 200.h,
                    width: 200.w,
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
                  AppTextFormField(
                    onChanged: (value) => _email = value,
                    keyboardType: TextInputType.emailAddress,
                    hint: AppStrings.emailLabel.tr(),
                    validator: emailValidator,
                  ),
                  SizedBox(height: 20.h),
                  // Password Field
                  AppTextFormField(
                    onChanged: (value) => _password = value,
                    obscureText: !_isPasswordVisible,
                    hint: AppStrings.passwordLabel.tr(),
                    validator: passwordValidator,
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
