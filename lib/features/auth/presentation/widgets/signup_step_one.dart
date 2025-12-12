import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/text_input.dart';

import '../models/signup_form_data.dart';

class SignupStepOne extends StatefulWidget {
  const SignupStepOne({
    super.key,
    required this.formData,
    required this.onDataChanged,
    required this.formKey,
  });

  final SignupFormData formData;
  final ValueChanged<SignupFormData> onDataChanged;
  final GlobalKey<FormState> formKey;

  @override
  State<SignupStepOne> createState() => _SignupStepOneState();
}

class _SignupStepOneState extends State<SignupStepOne> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Image.asset(AppAssets.images.logo, height: 120.h, width: 120.w),
          SizedBox(height: 40.h),
          // Title
          Text(
            AppStrings.signUpTitle.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          // Subtitle
          Text(
            AppStrings.signInDescription.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 40.h),
          // Email Field
          InputLabel(label: AppStrings.emailLabel.tr()),
          SizedBox(height: 8.h),
          AppTextFormField(
            initialValue: widget.formData.email,
            onChanged: (value) {
              widget.onDataChanged(widget.formData.copyWith(email: value));
            },
            keyboardType: TextInputType.emailAddress,
            label: AppStrings.emailLabel.tr(),
            hint: AppStrings.emailHint.tr(),
            validator: emailValidator,
          ),
          SizedBox(height: 16.h),
          // Password Field
          InputLabel(label: AppStrings.passwordLabel.tr()),
          SizedBox(height: 8.h),
          AppTextFormField(
            initialValue: widget.formData.password,
            onChanged: (value) {
              widget.onDataChanged(widget.formData.copyWith(password: value));
            },
            hint: AppStrings.passwordLabel.tr(),
            obscureText: !_isPasswordVisible,
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
            initialValue: widget.formData.confirmPassword,
            onChanged: (value) {
              widget.onDataChanged(
                widget.formData.copyWith(confirmPassword: value),
              );
            },
            hint: AppStrings.confirmPasswordHint.tr(),
            obscureText: !_isPasswordVisible,
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
            validator: (value) =>
                confirmPasswordValidator(value, widget.formData.password),
          ),
          SizedBox(height: 16.h),
          // Terms Checkbox
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                AppStrings.agreeTerms.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 24.w,
                height: 24.h,
                child: Checkbox(
                  value: widget.formData.agreeToTerms,
                  onChanged: (value) {
                    widget.onDataChanged(
                      widget.formData.copyWith(agreeToTerms: value ?? false),
                    );
                  },
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
