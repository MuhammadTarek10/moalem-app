import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/animations.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const LoadingScreen({super.key, this.message, this.isFullScreen = true});

  @override
  Widget build(BuildContext context) {
    // Inline loading (used inside existing Scaffold)
    if (!isFullScreen) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo Container
            Container(
              width: 100.w,
              height: 100.w,
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
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Image.asset(
                      AppAssets.images.logo,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ).scaleShimmerShake(
              duration: 1000,
              color: AppColors.primary.withValues(alpha: 0.3),
              hz: 2,
              curve: Curves.easeInOut,
              delay: 300,
            ),

            SizedBox(height: 32.h),

            // Loading Indicator
            _LoadingDots(isInline: true).fadeIn(duration: 600, delay: 400),

            if (message != null) ...[
              SizedBox(height: 20.h),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 20.sp,
                  color: AppColors.textSubtitle,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).fadeIn(duration: 600, delay: 600),
            ],
          ],
        ),
      );
    }

    // Full screen loading
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo Container
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Image.asset(
                    AppAssets.images.logo,
                    fit: BoxFit.contain,
                  ),
                ),
              ).scaleShimmerShake(
                duration: 1000,
                color: Colors.white.withValues(alpha: 0.3),
                hz: 2,
                curve: Curves.easeInOut,
                delay: 300,
              ),

              SizedBox(height: 40.h),

              // Loading Indicator
              _LoadingDots().fadeIn(duration: 600, delay: 400),

              SizedBox(height: 24.h),

              // Message
              if (message != null)
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 22.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ).fadeIn(duration: 600, delay: 600),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  final bool isInline;

  const _LoadingDots({this.isInline = false});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -15,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        _controllers[i].repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isInline ? AppColors.primary : Colors.white;
    final glowColor = widget.isInline
        ? AppColors.primary.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                width: 14.w,
                height: 14.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [
                    BoxShadow(color: glowColor, blurRadius: 8, spreadRadius: 2),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
