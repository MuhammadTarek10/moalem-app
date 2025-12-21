import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';

class ClassCard extends StatelessWidget {
  final String id;
  final String className;
  final String section;
  final int studentCount;
  final VoidCallback? onViewStudents;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClassCard({
    super.key,
    required this.id,
    required this.className,
    required this.section,
    required this.studentCount,
    this.onViewStudents,
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
                // Section
                Text(
                  section,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 18.sp, color: AppColors.textLight),
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
          // Bottom section - View students button
          GestureDetector(
            onTap: onViewStudents,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.viewStudents.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 20.w,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
