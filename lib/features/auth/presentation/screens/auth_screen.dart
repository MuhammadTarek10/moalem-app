import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/widgets/app_button.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(AppAssets.images.logo, fit: BoxFit.cover),
              ),

              // App Title
              Text(
                AppStrings.appTitle.tr(),
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
              ),

              // Subtitle
              Text(
                AppStrings.authSubtitle.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              SizedBox(height: 24.h),

              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return AppButton(
                      onPressed: () => context.push(AppRoutes.signUp),
                      text: AppStrings.createNewAccount.tr(),
                    );
                  }
                  return AppButton(
                    outlined: true,
                    onPressed: () => context.push(AppRoutes.signIn),
                    text: AppStrings.signInButton.tr(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
