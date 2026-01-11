import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';

class PrintOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const PrintOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.primaryLightest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.inactiveBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Title on the right (RTL)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'طباعة',
                    style: context.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    title,
                    style: context.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Icon circle on the left (RTL)
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: iconColor ?? AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40.sp, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
