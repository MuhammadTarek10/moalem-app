import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/shared/colors/app_colors.dart';

class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AppFloatingActionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: UniqueKey(),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.secondary,
        elevation: 0,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          AppAssets.icons.add,
          width: 24.w,
          height: 24.w,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
