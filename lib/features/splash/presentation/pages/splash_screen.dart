import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/animations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Simulate loading or check auth status here
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      final storage = getIt<StorageService>();
      final isLoggedIn = storage.getBool(AppKeys.isLoggedIn) ?? false;
      if (isLoggedIn) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.auth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Placeholder
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(AppAssets.images.logo, fit: BoxFit.cover),
            ).scaleShimmerShake(
              duration: 600,
              color: Colors.white.withValues(alpha: 0.5),
              hz: 4,
              curve: Curves.easeInOutCubic,
              delay: 200,
            ),

            SizedBox(height: 24.h),

            // App Name
            Text(
              AppStrings.appTitle.tr(),
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).fadeIn(duration: 600, delay: 400),

            SizedBox(height: 8.h),

            // Tagline
            Text(
              AppStrings.appTagline.tr(),
              style: TextStyle(
                fontSize: 32.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ).fadeIn(duration: 600, delay: 800),
          ],
        ),
      ),
    );
  }
}
