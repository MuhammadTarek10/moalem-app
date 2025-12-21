import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/auth/presentation/controllers/auth_controller.dart';
import 'package:moalem/features/profile/presentation/controllers/profile_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/widgets/app_button.dart';
import 'package:moalem/shared/widgets/profile_menu_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(profileControllerProvider);

    return Scaffold(
      body: userState.when(
        data: (User user) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: Column(
              children: [
                // User Info Section
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60.w,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(user.name ?? '', style: context.headlineMedium),
                    SizedBox(height: 8.h),
                    Text('ID: ${user.id ?? ''}', style: context.bodyMedium),
                  ],
                ),
                SizedBox(height: 32.h),

                // Menu Items
                ProfileMenuButton(
                  title: AppStrings.profileMenuProfile.tr(),
                  icon: AppAssets.icons.profileActive,
                  onTap: () => context.push(AppRoutes.profile),
                ),
                ProfileMenuButton(
                  title: AppStrings.profileMenuAdvancedSettings.tr(),
                  icon: AppAssets.icons.settings,
                  onTap: () => context.push(AppRoutes.advancedSettings),
                ),
                ProfileMenuButton(
                  title: AppStrings.profileMenuRateUs.tr(),
                  icon: AppAssets.icons.star,
                  onTap: () => context.push(AppRoutes.rateUs),
                ),
                ProfileMenuButton(
                  title: AppStrings.profileMenuContactUs.tr(),
                  icon: AppAssets.icons.callUs,
                  onTap: () => context.push(AppRoutes.contactUs),
                ),

                SizedBox(height: 32.h),

                // Logout Button
                AppButton(
                  isDestructive: true,
                  onPressed: () => {
                    ref.read(authControllerProvider.notifier).signOut(),
                    context.go(AppRoutes.signIn),
                  },
                  outlined: true,
                  text: AppStrings.profileMenuLogout.tr(),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorScreen(
          isFullScreen: false,
          message: ErrorHandler.getErrorMessage(error),
          onRetry: () => ref.read(profileControllerProvider.notifier).getUser(),
        ),
      ),
    );
  }
}
