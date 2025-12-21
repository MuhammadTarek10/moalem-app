import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/widgets/app_button.dart';

class StudentsEmptyState extends StatelessWidget {
  final VoidCallback? onAddManually;
  final VoidCallback? onAttachExcel;

  const StudentsEmptyState({super.key, this.onAddManually, this.onAttachExcel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular avatar icon
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLighter,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 64.w,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 32.h),

            // Title
            Text(
              AppStrings.noStudentsTitle.tr(),
              style: context.headlineMedium.copyWith(color: AppColors.textMain),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),

            // Subtitle
            Text(
              AppStrings.noStudentsSubtitle.tr(),
              style: context.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),

            // Add Manually Button
            AppButton(
              onPressed: onAddManually,
              text: AppStrings.addStudentManually.tr(),
            ),
            SizedBox(height: 16.h),
            // Attach Excel Button
            AppButton(
              onPressed: onAttachExcel,
              text: AppStrings.addStudentsExcel.tr(),
              outlined: true,
            ),
          ],
        ),
      ),
    );
  }
}
