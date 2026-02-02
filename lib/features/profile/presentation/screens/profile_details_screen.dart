import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/profile/presentation/controllers/profile_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/screens/loading_screen.dart';
import 'package:moalem/shared/widgets/app_app_bar.dart';

class ProfileDetailsScreen extends ConsumerWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppAppBar(title: AppStrings.profileMenuProfile.tr()),
      body: userState.when(
        data: (User user) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            children: [
              // Avatar & Name Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60.w,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      user.name ?? '',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (user.id != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${user.id}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Info Items
              _buildInfoSection(
                context,
                title: AppStrings.signUpTitle.tr(), // Or Personal Info
                children: [
                  _buildInfoItem(
                    icon: Icons.email_outlined,
                    label: AppStrings.emailLabel.tr(),
                    value: user.email,
                  ),
                  _buildInfoItem(
                    icon: Icons.phone_android,
                    label: AppStrings.whatsappLabel.tr(),
                    value: user.whatsappNumber,
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              _buildInfoSection(
                context,
                title: '', // Section title removed
                children: [
                  _buildInfoItem(
                    icon: Icons.location_city,
                    label: AppStrings.governorateLabel.tr(),
                    value: user.governorate,
                  ),
                  _buildInfoItem(
                    icon: Icons.business,
                    label: AppStrings.administrationLabel.tr(),
                    value: user.educationalAdministration,
                  ),
                  _buildInfoItem(
                    icon: Icons.school_outlined,
                    label: AppStrings.schoolLabel.tr(),
                    value: user.schools.join(', '),
                  ),
                  _buildInfoItem(
                    icon: Icons.grade_outlined,
                    label: AppStrings.gradeLabel.tr(),
                    value: user.grades.join(', '),
                  ),
                  _buildInfoItem(
                    icon: Icons.book_outlined,
                    label: AppStrings.subjectLabel.tr(),
                    value: user.subjects.join(', '),
                  ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const LoadingScreen(isFullScreen: false),
        error: (error, stack) => ErrorScreen(
          isFullScreen: false,
          message: ErrorHandler.getErrorMessage(error),
          onRetry: () => ref.read(profileControllerProvider.notifier).getUser(),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 12.h),*/
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 2.h),
                Text(
                  value ?? '-',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
