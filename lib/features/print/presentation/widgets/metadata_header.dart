import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';

class MetadataHeader extends StatelessWidget {
  final String governorate;
  final String administration;
  final String school;
  final String className;
  final String subject;
  final String period;

  const MetadataHeader({
    super.key,
    required this.governorate,
    required this.administration,
    required this.school,
    required this.className,
    required this.subject,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryLightest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.inactiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.reportHeader.tr(),
            style: context.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          _buildMetadataRow(context, AppStrings.governorate.tr(), governorate),
          SizedBox(height: 8.h),
          _buildMetadataRow(
            context,
            AppStrings.administration.tr(),
            administration,
          ),
          SizedBox(height: 8.h),
          _buildMetadataRow(context, AppStrings.schoolLabel.tr(), school),
          SizedBox(height: 8.h),
          _buildMetadataRow(context, AppStrings.classLabel.tr(), className),
          SizedBox(height: 8.h),
          _buildMetadataRow(context, AppStrings.subjectClass.tr(), subject),
          SizedBox(height: 8.h),
          _buildMetadataRow(context, AppStrings.periodLabel.tr(), period),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: context.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: context.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
