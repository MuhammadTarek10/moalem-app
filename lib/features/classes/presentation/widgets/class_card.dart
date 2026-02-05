import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';

class ClassCard extends StatelessWidget {
  final String id;
  final String className;
  final String stage;
  final String grade;
  final String subject;
  final int studentCount;
  final VoidCallback? onViewStudents;
  final VoidCallback? onAddScores;
  final VoidCallback? onAddAttendance;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClassCard({
    super.key,
    required this.id,
    required this.className,
    required this.stage,
    required this.grade,
    required this.subject,
    required this.studentCount,
    this.onViewStudents,
    this.onAddScores,
    this.onAddAttendance,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(id),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3.4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section - Class info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class name and options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      className,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              SizedBox(width: 8.w),
                              Text(AppStrings.editButton.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                AppStrings.deleteButton.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Stage, Grade and Subject
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' | ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      grade,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      ' - ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      stage,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Student count
                Text(
                  AppStrings.studentCount.tr(args: [studentCount.toString()]),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textMain,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Bottom section - Action buttons
          Row(
            children: [
              // View Students button
              Expanded(
                child: GestureDetector(
                  onTap: onViewStudents,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightest,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(8.r),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          color: AppColors.primary,
                          size: 20.w,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          AppStrings.viewStudents.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 52.h,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              // Add Attendance button
              Expanded(
                child: GestureDetector(
                  onTap: onAddAttendance,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLightest,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          color: AppColors.primary,
                          size: 20.w,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          AppStrings.attendance.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 52.h,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              // Add Scores button
              Expanded(
                child: GestureDetector(
                  onTap: onAddScores,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightest,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8.r),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, color: AppColors.primary, size: 20.w),
                        SizedBox(height: 4.h),
                        Text(
                          AppStrings.addScores.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
