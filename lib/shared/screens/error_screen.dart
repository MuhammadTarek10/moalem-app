import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/animations.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/widgets/app_button.dart';

class ErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final IconData? icon;
  final bool isFullScreen;

  const ErrorScreen({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onGoBack,
    this.icon,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Error Icon
            _AnimatedErrorIcon(icon: icon).fadeIn(duration: 600, delay: 0),

            SizedBox(height: 40.h),

            // Title
            Text(
              title ?? AppStrings.errorTitle.tr(),
              style: context.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).fadeIn(duration: 600, delay: 200),

            SizedBox(height: 16.h),

            // Message
            Text(
              message ?? AppStrings.errorMessage.tr(),
              style: context.bodyLarge.copyWith(
                color: AppColors.textSubtitle,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).fadeIn(duration: 600, delay: 400),

            SizedBox(height: 48.h),

            // Action Buttons
            Column(
              children: [
                if (onRetry != null)
                  AppButton(
                    onPressed: onRetry,
                    text: AppStrings.errorRetry.tr(),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22.w,
                    ),
                  ).fadeIn(duration: 600, delay: 600),
                if (onRetry != null && onGoBack != null) SizedBox(height: 16.h),
                if (onGoBack != null)
                  AppButton(
                    onPressed: onGoBack,
                    text: AppStrings.errorGoBack.tr(),
                    outlined: true,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: 22.w,
                    ),
                  ).fadeIn(duration: 600, delay: 800),
              ],
            ),
          ],
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(backgroundColor: AppColors.background, body: content);
    }

    return content;
  }
}

class _AnimatedErrorIcon extends StatefulWidget {
  final IconData? icon;

  const _AnimatedErrorIcon({this.icon});

  @override
  State<_AnimatedErrorIcon> createState() => _AnimatedErrorIconState();
}

class _AnimatedErrorIconState extends State<_AnimatedErrorIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.8,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: -0.05,
          end: 0.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.05,
          end: -0.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.05,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(angle: _rotateAnimation.value, child: child),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow circle
          Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.error.withValues(alpha: 0.2),
                  AppColors.error.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
          ),
          // Inner circle with icon
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon ?? Icons.error_outline_rounded,
                  size: 44.w,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
