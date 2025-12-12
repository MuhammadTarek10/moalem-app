import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/auth/data/static/egypt_regions.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/chip_input.dart';
import 'package:moalem/shared/widgets/text_input.dart';

import '../models/signup_form_data.dart';

class SignupStepThree extends StatelessWidget {
  const SignupStepThree({
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
    final administrations = formData.governorate != null
        ? EgyptRegions.getAdministrations(formData.governorate!)
        : <String>[];

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
          // Governorate and Administration Row
          Row(
            children: [
              // Educational Administration
              // Governorate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputLabel(label: AppStrings.governorateLabel.tr()),
                    SizedBox(height: 8.h),
                    DropdownField(
                      value: formData.governorate,
                      items: EgyptRegions.governorates,
                      onChanged: (value) {
                        // Reset administration when governorate changes
                        onDataChanged(
                          formData.copyWith(
                            governorate: value,
                            educationalAdministration: null,
                          ),
                        );
                      },
                      hint: AppStrings.governorateLabel.tr(),
                      validator: requiredValidator,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputLabel(label: AppStrings.administrationLabel.tr()),
                    SizedBox(height: 8.h),
                    DropdownField(
                      value: formData.educationalAdministration,
                      items: administrations,
                      onChanged: (value) {
                        onDataChanged(
                          formData.copyWith(educationalAdministration: value),
                        );
                      },
                      hint: AppStrings.administrationLabel.tr(),
                      validator: requiredValidator,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // School Name Field (Chip Input)
          InputLabel(label: AppStrings.schoolLabel.tr()),
          SizedBox(height: 8.h),
          ChipInputField(
            selectedItems: formData.schools,
            onItemsChanged: (items) {
              onDataChanged(formData.copyWith(schools: items));
            },
            hint: AppStrings.schoolHint.tr(),
            validator: listValidator,
          ),
          SizedBox(height: 16.h),
          // Grade Field (Chip Input)
          InputLabel(label: AppStrings.gradeLabel.tr()),
          SizedBox(height: 8.h),
          ChipInputField(
            selectedItems: formData.grades,
            onItemsChanged: (items) {
              onDataChanged(formData.copyWith(grades: items));
            },
            hint: AppStrings.gradeHint.tr(),
            validator: listValidator,
          ),
        ],
      ),
    );
  }
}
