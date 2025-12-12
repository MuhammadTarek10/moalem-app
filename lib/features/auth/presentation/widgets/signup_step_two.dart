import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/chip_input.dart';
import 'package:moalem/shared/widgets/text_input.dart';

import '../models/signup_form_data.dart';

class SignupStepTwo extends StatelessWidget {
  const SignupStepTwo({
    super.key,
    required this.formData,
    required this.onDataChanged,
    required this.formKey,
  });

  final SignupFormData formData;
  final ValueChanged<SignupFormData> onDataChanged;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Image.asset(AppAssets.images.logo, height: 120.h, width: 120.w),
          SizedBox(height: 24.h),
          // Title
          Text(
            AppStrings.appTitle.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          // Subtitle
          Text(
            AppStrings.authSubtitle.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 40.h),
          // Full Name Field
          InputLabel(label: AppStrings.fullNameLabel.tr()),
          SizedBox(height: 8.h),
          AppTextFormField(
            initialValue: formData.fullName,
            onChanged: (value) {
              onDataChanged(formData.copyWith(fullName: value));
            },
            hint: AppStrings.fullNameHint.tr(),
            validator: requiredValidator,
          ),
          SizedBox(height: 16.h),
          // Subject Field (Chip Input)
          InputLabel(label: AppStrings.subjectLabel.tr()),
          SizedBox(height: 8.h),
          ChipInputField(
            selectedItems: formData.subjects,
            onItemsChanged: (items) {
              onDataChanged(formData.copyWith(subjects: items));
            },
            hint: AppStrings.subjectHint.tr(),
            validator: listValidator,
          ),
          SizedBox(height: 16.h),
          // WhatsApp Number Field
          InputLabel(label: AppStrings.whatsappLabel.tr()),
          SizedBox(height: 8.h),
          AppTextFormField(
            initialValue: formData.whatsappNumber,
            onChanged: (value) {
              onDataChanged(formData.copyWith(whatsappNumber: value));
            },
            keyboardType: TextInputType.phone,
            hint: AppStrings.whatsappHint.tr(),
            validator: requiredValidator,
          ),
        ],
      ),
    );
  }
}
