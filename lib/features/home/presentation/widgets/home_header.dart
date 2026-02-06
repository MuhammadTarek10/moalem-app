import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/shared/colors/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final User? user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                // Notification/Message Icon (Left in LTR, Right in RTL?)
                // Assuming standard AppBar-like layout: Leading icon, Title/User info, Trailing/Avatar
                // Based on image: Left side has an icon (looks like message bubble). Right side has Avatar. Text in middle/right.
                // RTL: Icon (Left), Text (Right), Avatar (Rightmost).
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.welcome.tr()} ${user?.name ?? ''}',
                      style: TextStyle(
                        fontSize: 25.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // SizedBox(height: 4.h),
                    Text(
                      '${AppStrings.yourIdLabel.tr()}: ${user?.id ?? ''}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Search Bar
          ],
        ),
      ),
    );
  }
}
