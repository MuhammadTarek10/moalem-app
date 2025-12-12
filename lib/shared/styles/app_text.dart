import 'package:flutter/material.dart';
import 'package:moalem/shared/colors/app_colors.dart';

extension TextButtonExtension on TextStyle {
  TextStyle get hyperLinkText => copyWith(
    color: AppColors.textPrimary,
    decoration: TextDecoration.underline,
    fontWeight: FontWeight.bold,
  );
}
