import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';

class HomeClassItem extends StatelessWidget {
  final String className;
  final String grade;
  final int studentsCount;
  final String semester;
  final VoidCallback onTap;

  const HomeClassItem({
    super.key,
    required this.className,
    required this.grade,
    required this.studentsCount,
    required this.semester,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            // Ensure RTL direction for the card content
            children: [
              // Purple accent strip (Right side for RTL)
              Container(
                width: 4.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF7A1C9A),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8.r),
                    bottomRight: Radius.circular(8.r),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        AppStrings.classNameLabel.tr(),
                        className,
                        true,
                      ),
                      SizedBox(height: 8.h),
                      _buildInfoRow(AppStrings.yearLabel.tr(), grade, false),
                      SizedBox(height: 8.h),
                      _buildInfoRow(
                        AppStrings.studentCountLabel.tr(),
                        studentsCount.toString(),
                        false,
                      ),
                      SizedBox(height: 8.h),
                      _buildInfoRow(
                        AppStrings.semesterLabel.tr(),
                        semester,
                        false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          '$label :- ',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              color: isBold ? Colors.black : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
