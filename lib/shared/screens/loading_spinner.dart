import 'package:flutter/material.dart';
import 'package:moalem/shared/colors/app_colors.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2);
  }
}
