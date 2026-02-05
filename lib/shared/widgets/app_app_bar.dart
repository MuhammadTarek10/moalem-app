import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/colors/app_colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final double? elevation;
  final Color? backgroundColor;
  final Color? titleColor;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.elevation = 0,
    this.backgroundColor = Colors.white,
    this.titleColor = AppColors.textMain,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      elevation: elevation,
      backgroundColor: backgroundColor,
      iconTheme: IconThemeData(color: titleColor),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
