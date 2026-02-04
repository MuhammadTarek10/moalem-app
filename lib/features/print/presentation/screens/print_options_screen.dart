import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
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
              // Stage selector dropdown
              _buildStageSelector(context, state, controller, classes),

              // Class selector dropdown
              _buildClassSelector(context, state, controller, classes),

              // Page selector for PrePrimary (if applicable)
              // Show page selector for PrePrimary (1-2 ابتدائي)
              if (state.printData.hasValue &&
                  state.printData.value?.classEntity.evaluationGroup.name ==
                      'prePrimary')
                _buildPageSelector(context, state, controller),

              // Show month selector for High School (ثانوي)
              if (state.printData.hasValue &&
                  state.printData.value?.classEntity.evaluationGroup.name ==
                      'high')
                _buildMonthSelector(context, state, controller),

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

  Widget _buildStageSelector(
    BuildContext context,
    PrintState state,
    PrintController controller,
    List<ClassEntity> classes,
  ) {
    final stages = classes
        .map((c) => c.stage)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (stages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.educationalStageHint.tr(),
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
                value: state.selectedStage,
                hint: Text(AppStrings.allStages.tr()),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(AppStrings.allStages.tr()),
                  ),
                  ...stages.map<DropdownMenuItem<String>>(
                    (s) => DropdownMenuItem(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (value) {
                  controller.selectStage(value);
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

  Widget _buildClassSelector(
    BuildContext context,
    PrintState state,
    PrintController controller,
    List<ClassEntity> classes,
  ) {
    final filteredClasses = classes
        .where(
          (c) => state.selectedStage == null || c.stage == state.selectedStage,
        )
        .toList();

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
                items: filteredClasses
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

  Widget _buildPageSelector(
    BuildContext context,
    PrintState state,
    PrintController controller,
  ) {
    final pages = [
      {'label': 'الصفحة 1 (أسابيع 1-5)', 'value': 1},
      {'label': 'الصفحة 2 (أسابيع 6-10)', 'value': 2},
      {'label': 'الصفحة 3 (أسابيع 11-15)', 'value': 3},
      {'label': 'الصفحة 4 (أسابيع 16-18)', 'value': 4},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر الصفحة للتصدير',
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: pages.map((page) {
              final isSelected = state.weekGroup == page['value'];
              return ChoiceChip(
                label: Text(page['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.changeWeekGroup(page['value'] as int);
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: context.bodySmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.inactiveBorder,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build month selector for High School (ثانوي) - 3 months
  Widget _buildMonthSelector(
    BuildContext context,
    PrintState state,
    PrintController controller,
  ) {
    final months = [
      {'label': 'شهر فبراير (أسابيع 1-4)', 'value': 1},
      {'label': 'شهر مارس (أسابيع 5-8)', 'value': 2},
      {'label': 'شهر أبريل (أسابيع 9-12)', 'value': 3},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر الشهر للتصدير',
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: months.map((month) {
              final isSelected = state.weekGroup == month['value'];
              return ChoiceChip(
                label: Text(month['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.changeWeekGroup(month['value'] as int);
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: context.bodySmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.inactiveBorder,
                ),
              );
            }).toList(),
          ),
        ],
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
