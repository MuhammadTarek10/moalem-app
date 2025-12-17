import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? icon;
  final TextStyle? textStyle;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.outlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? (outlined ? Colors.transparent : AppColors.primary);
    final effectiveForegroundColor =
        foregroundColor ?? (outlined ? AppColors.primary : Colors.white);

    return ElevatedButton(
      key: ValueKey(isLoading),
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: AppColors.disabled,
        foregroundColor: effectiveForegroundColor,
        elevation: outlined ? 0 : null,
        backgroundColor: effectiveBackgroundColor,
        side: outlined
            ? const BorderSide(color: AppColors.primary)
            : BorderSide.none,
        minimumSize: Size(double.infinity, 44.h),
        maximumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, SizedBox(width: 8.w)],
                Text(
                  text,
                  style:
                      textStyle ??
                      context.headlineSmall.copyWith(
                        color: outlined
                            ? AppColors.primary
                            : context.textPrimaryColor,
                      ),
                ),
              ],
            ),
    );
  }
}
