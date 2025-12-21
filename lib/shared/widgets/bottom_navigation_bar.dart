import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final PersistentTabController controller;
  final List<Widget> screens;

  const AppBottomNavigationBar({
    super.key,
    required this.controller,
    required this.screens,
  });

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: controller,
      screens: screens,
      animationSettings: NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
        screenTransitionAnimation: ScreenTransitionAnimationSettings(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      items: _navBarItems(),
      backgroundColor: AppColors.surface,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.zero,
        colorBehindNavBar: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 0,
            offset: const Offset(0, -1),
            spreadRadius: 1,
          ),
        ],
      ),
      navBarStyle: NavBarStyle.style6,
      navBarHeight: 70.h,
    );
  }

  List<PersistentBottomNavBarItem> _navBarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset(
          AppAssets.icons.homeInactive,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        inactiveIcon: SvgPicture.asset(
          AppAssets.icons.homeInactive,
          colorFilter: const ColorFilter.mode(
            AppColors.inactive,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        title: AppStrings.navHome.tr(),
        activeColorPrimary: AppColors.textPrimary,
        inactiveColorPrimary: AppColors.inactive,
        textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset(
          AppAssets.icons.classesActive,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        inactiveIcon: SvgPicture.asset(
          AppAssets.icons.classesInactive,
          colorFilter: const ColorFilter.mode(
            AppColors.inactive,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        title: AppStrings.navClasses.tr(),
        activeColorPrimary: AppColors.textPrimary,
        inactiveColorPrimary: AppColors.inactive,
        textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset(
          AppAssets.icons.print,
          width: 24.w,
          height: 24.h,
        ),
        inactiveIcon: SvgPicture.asset(
          AppAssets.icons.print,
          width: 24.w,
          height: 24.h,
        ),
        title: AppStrings.navPrint.tr(),
        activeColorPrimary: AppColors.textPrimary,
        inactiveColorPrimary: AppColors.inactive,
        textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset(
          AppAssets.icons.reportsActive,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        inactiveIcon: SvgPicture.asset(
          AppAssets.icons.reportsInactive,
          colorFilter: const ColorFilter.mode(
            AppColors.inactive,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        title: AppStrings.navReports.tr(),
        activeColorPrimary: AppColors.textPrimary,
        inactiveColorPrimary: AppColors.inactive,
        textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset(
          AppAssets.icons.profileActive,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        inactiveIcon: SvgPicture.asset(
          AppAssets.icons.profileInactive,
          colorFilter: const ColorFilter.mode(
            AppColors.inactive,
            BlendMode.srcIn,
          ),
          width: 24.w,
          height: 24.h,
        ),
        title: AppStrings.navProfile.tr(),
        activeColorPrimary: AppColors.textPrimary,
        inactiveColorPrimary: AppColors.inactive,
        textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
    ];
  }
}
