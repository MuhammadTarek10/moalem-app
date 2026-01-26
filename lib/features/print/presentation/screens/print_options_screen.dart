import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/print/presentation/controllers/print_controller.dart';
import 'package:moalem/features/print/presentation/widgets/export_buttons.dart';
import 'package:moalem/features/print/presentation/widgets/metadata_header.dart';
import 'package:moalem/features/profile/presentation/controllers/profile_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/screens/loading_screen.dart';

class PrintOptionsScreen extends ConsumerWidget {
  final String classId;
  final String printType;

  const PrintOptionsScreen({
    super.key,
    required this.classId,
    required this.printType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(printControllerProvider(printType));
    final controller = ref.read(printControllerProvider(printType).notifier);
    final userAsyncValue = ref.watch(profileControllerProvider);

    // Listen for export messages
    ref.listen(printControllerProvider(printType), (previous, next) {
      if (next.exportMessage != null &&
          next.exportMessage != previous?.exportMessage) {
        context.showSuccessSnackBar(next.exportMessage!);
        controller.clearExportMessage();
      }
    });

    // If classId provided, select it
    if (classId.isNotEmpty && state.selectedClassId != classId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectClass(classId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          printType == 'attendance'
              ? AppStrings.studentAttendance.tr()
              : AppStrings.studentScores.tr(),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: state.classes.when(
        loading: () => const LoadingScreen(),
        error: (error, _) => ErrorScreen(
          message: ErrorHandler.getErrorMessage(error),
          onRetry: () => controller.loadClasses(),
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Text(
                AppStrings.noClassesTitle.tr(),
                style: context.bodyLarge.copyWith(color: AppColors.textLight),
              ),
            );
          }

          return Column(
            children: [
              // Class selector dropdown
              _buildClassSelector(context, state, controller, classes),

              // Period selector
              _buildPeriodSelector(context, state, controller),

              // Data preview
              Expanded(
                child: state.printData.when(
                  loading: () => const LoadingScreen(),
                  error: (error, _) => ErrorScreen(
                    message: ErrorHandler.getErrorMessage(error),
                    onRetry: () => controller.loadPrintData(),
                  ),
                  data: (printData) {
                    if (printData == null || printData.studentsData.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.noData.tr(),
                          style: context.bodyLarge.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      );
                    }

                    return _buildDataPreview(
                      context,
                      printData,
                      userAsyncValue,
                    );
                  },
                ),
              ),

              // Export buttons
              ExportButtons(
                onExportExcel: () => controller.exportToExcel(),
                onExportPdf: () => controller.exportToPdf(),
                onExportEmptySheet: () => controller.exportEmptySheet(),
                isExcelLoading: state.isExportingExcel,
                isPdfLoading: state.isExportingPdf,
                isEmptySheetLoading: state.isExportingEmptySheet,
                showEmptySheetButton: printType == 'attendance',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClassSelector(
    BuildContext context,
    PrintState state,
    PrintController controller,
    List classes,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.selectClass.tr(),
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryLightest,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.inactiveBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.selectedClassId,
                items: classes
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.selectClass(value);
                },
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textLight,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    PrintState state,
    PrintController controller,
  ) {
    // Both scores and attendance now use week group selector (5 weeks at a time)
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            AppStrings.periodLabel.tr(),
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.inactiveBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: _buildWeekGroupDropdown(state, controller),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Week group dropdown for both scores and attendance (weeks 1-5, 6-10, 11-15)
  Widget _buildWeekGroupDropdown(PrintState state, PrintController controller) {
    return DropdownButton<int>(
      isExpanded: true,
      value: state.weekGroup,
      items: [
        DropdownMenuItem(value: 1, child: Text('الأسابيع 1 - 5')),
        DropdownMenuItem(value: 2, child: Text('الأسابيع 6 - 10')),
        DropdownMenuItem(value: 3, child: Text('الأسابيع 11 - 15')),
      ],
      onChanged: (value) {
        if (value != null) controller.changeWeekGroup(value);
      },
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.textLight,
        size: 20.sp,
      ),
    );
  }

  Widget _buildDataPreview(
    BuildContext context,
    printData,
    AsyncValue userAsyncValue,
  ) {
    // Get administration from user, fallback to printData if user not available
    final administration =
        userAsyncValue.whenOrNull(
          data: (user) =>
              user.educationalAdministration ?? printData.administration,
        ) ??
        printData.administration;

    // Determine period text based on multi-week or single week
    String periodText;
    if (printData.isMultiWeek) {
      final weekNums = printData.weekNumbers;
      periodText = 'الأسابيع ${weekNums.first} - ${weekNums.last}';
    } else {
      periodText = '${AppStrings.weekly.tr()} ${printData.periodNumber}';
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Metadata header
          MetadataHeader(
            governorate: printData.governorate,
            administration: administration,
            school: printData.classEntity.school,
            className: printData.classEntity.name,
            subject: printData.classEntity.subject,
            period: periodText,
          ),

          // Students preview (simplified)
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.inactiveBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${printData.studentsData.length} ${AppStrings.studentCount.tr().replaceAll('{}', '')}',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ...printData.studentsData.take(5).map<Widget>((studentData) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      children: [
                        Text(
                          studentData.student.number.toString(),
                          style: context.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            studentData.student.name,
                            style: context.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (printData.studentsData.length > 5) ...[
                  SizedBox(height: 8.h),
                  Text(
                    '...',
                    style: context.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
