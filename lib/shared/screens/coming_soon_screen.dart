import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/animations.dart';
import 'package:moalem/shared/extensions/context.dart';

class ComingSoonScreen extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onBackPressed;

  const ComingSoonScreen({
    super.key,
    this.title,
    this.subtitle,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 24.w,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon Container
              Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 56.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).scaleShimmerShake(
                duration: 800,
                color: AppColors.primary.withValues(alpha: 0.3),
                hz: 3,
                curve: Curves.easeInOutCubic,
                delay: 200,
              ),

              SizedBox(height: 48.h),

              // Title
              Text(
                title ?? AppStrings.comingSoonTitle.tr(),
                style: context.headlineLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).fadeIn(duration: 600, delay: 300),

              SizedBox(height: 16.h),

              // Subtitle
              Text(
                subtitle ?? AppStrings.comingSoonSubtitle.tr(),
                style: context.bodyLarge.copyWith(
                  color: AppColors.textSubtitle,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).fadeIn(duration: 600, delay: 500),

              SizedBox(height: 48.h),

              // Decorative Progress Indicator
              _ComingSoonProgress().fadeIn(duration: 600, delay: 700),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonProgress extends StatefulWidget {
  @override
  State<_ComingSoonProgress> createState() => _ComingSoonProgressState();
}

class _ComingSoonProgressState extends State<_ComingSoonProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200.w,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value: _animation.value,
                      backgroundColor: AppColors.disabled,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 8.h,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '${(_animation.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppStrings.comingSoonProgress.tr(),
          style: TextStyle(fontSize: 16.sp, color: AppColors.textSubtitle),
        ),
      ],
    );
  }
}
