import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isLoading;
  final bool outlined;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: ValueKey(isLoading),
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: AppColors.disabled,
        foregroundColor: outlined ? AppColors.primary : Colors.white,
        elevation: outlined ? 0 : null,
        backgroundColor: outlined ? Colors.transparent : AppColors.primary,
        side: outlined
            ? const BorderSide(color: AppColors.primary)
            : BorderSide.none,
        minimumSize: Size(double.infinity, 56.h),
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
          : Text(
              text,
              style: context.headlineSmall.copyWith(
                color: outlined ? AppColors.primary : context.textPrimaryColor,
              ),
            ),
    );
  }
}
