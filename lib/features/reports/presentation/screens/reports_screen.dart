import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/reports/presentation/controllers/reports_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/screens/loading_screen.dart';

class ReportsScreen extends ConsumerWidget {
  final String? classId;

  const ReportsScreen({super.key, this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsControllerProvider);
    final controller = ref.read(reportsControllerProvider.notifier);

    // If classId provided, select it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (classId != null && state.selectedClassId != classId) {
        controller.selectClass(classId!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.classReports.tr()),
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
              // Filters row
              _buildFiltersRow(context, state, controller, classes),

              // Table
              Expanded(
                child: state.reportData.when(
                  loading: () => const LoadingScreen(),
                  error: (error, _) => ErrorScreen(
                    message: ErrorHandler.getErrorMessage(error),
                    onRetry: () => controller.loadReport(),
                  ),
                  data: (reportData) {
                    if (reportData == null ||
                        reportData.studentReports.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.noData.tr(),
                          style: context.bodyLarge.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      );
                    }

                    return _buildReportTable(
                      context,
                      state,
                      controller,
                      reportData,
                    );
                  },
                ),
              ),

              // Export buttons (only show when students are selected)
              if (state.selectedCount > 0)
                _buildExportButtons(context, state, controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersRow(
    BuildContext context,
    ReportsState state,
    ReportsController controller,
    List classes,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Column(
        children: [
          // Class selector
          _buildDropdown<String>(
            context,
            state.selectedClassId != null
                ? classes.firstWhere((c) => c.id == state.selectedClassId!).name
                : classes.first.name,
            classes
                .map<DropdownMenuItem<String>>(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                )
                .toList(),
            (value) {
              if (value != null) controller.selectClass(value);
            },
          ),
          SizedBox(height: 12.h),
          // Period filters row
          Row(
            children: [
              // Period number dropdown
              Expanded(
                child: _buildDropdown<int>(
                  context,
                  state.periodNumber.toString(),
                  List.generate(12, (index) => index + 1)
                      .map(
                        (n) => DropdownMenuItem(
                          value: n,
                          child: Text(n.toString()),
                        ),
                      )
                      .toList(),
                  (value) {
                    if (value != null) controller.changePeriodNumber(value);
                  },
                ),
              ),
              SizedBox(width: 12.w),
              // Period type (fixed to weekly)
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightest,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.inactiveBorder),
                  ),
                  child: Text(
                    AppStrings.weekly.tr(),
                    style: context.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context,
    String hint,
    List<DropdownMenuItem<T>> items,
    Function(T?) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.primaryLightest,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.inactiveBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(hint, style: context.bodySmall),
          items: items,
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textLight,
            size: 20.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildReportTable(
    BuildContext context,
    ReportsState state,
    ReportsController controller,
    reportData,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.textSecondary),
          headingTextStyle: context.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          dataRowMinHeight: 50.h,
          dataRowMaxHeight: 60.h,
          columnSpacing: 16.w,
          columns: [
            // Checkbox column
            DataColumn(label: Text(AppStrings.select.tr())),
            // Student number
            DataColumn(
              label: Text(
                AppStrings.studentNumberShort.tr(),
                textAlign: TextAlign.center,
              ),
            ),
            // Student name
            DataColumn(
              label: Text(
                AppStrings.studentNameShort.tr(),
                textAlign: TextAlign.center,
              ),
            ),
            // Evaluation columns
            ...reportData.evaluations.map((evaluation) {
              return DataColumn(
                label: SizedBox(
                  width: 80.w,
                  child: Text(
                    _getEvaluationShortName(evaluation.name),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
            // Total column
            DataColumn(
              label: Text(
                AppStrings.totalScoreShort.tr(),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          rows: reportData.studentReports.map<DataRow>((studentReport) {
            final isSelected = state.isStudentSelected(
              studentReport.student.id,
            );

            return DataRow(
              cells: [
                // Checkbox cell
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => controller.toggleStudentSelection(
                      studentReport.student.id,
                    ),
                    activeColor: AppColors.primary,
                  ),
                ),
                // Student number
                DataCell(
                  Text(
                    studentReport.student.number.toString(),
                    style: context.bodyMedium,
                  ),
                ),
                // Student name
                DataCell(
                  Text(studentReport.student.name, style: context.bodyMedium),
                ),
                // Score cells
                ...reportData.evaluations.map((evaluation) {
                  final score = studentReport.getScore(evaluation.id);
                  final maxScore = evaluation.maxScore;
                  final percentage = (score / maxScore) * 100;

                  return DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(percentage),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '$score/$maxScore',
                        style: context.bodySmall.copyWith(
                          color: percentage < 50
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
                // Total score cell
                DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(studentReport.percentage),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '${studentReport.totalScore}/${studentReport.maxPossibleScore}',
                      style: context.bodySmall.copyWith(
                        color: studentReport.percentage < 50
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExportButtons(
    BuildContext context,
    ReportsState state,
    ReportsController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${AppStrings.selectedCount.tr()} ${state.selectedCount}',
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          // Excel button
          ElevatedButton.icon(
            onPressed: () => controller.exportToExcel(),
            icon: const Icon(Icons.table_chart, size: 20),
            label: Text(AppStrings.exportExcel.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            ),
          ),
          SizedBox(width: 12.w),
          // PDF button
          ElevatedButton.icon(
            onPressed: () => controller.exportToPdf(),
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: Text(AppStrings.exportPdf.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green.withValues(alpha: 0.2);
    } else if (percentage >= 50) {
      return Colors.orange.withValues(alpha: 0.2);
    } else {
      return Colors.red.withValues(alpha: 0.8);
    }
  }

  String _getEvaluationShortName(String name) {
    switch (name) {
      case 'classroom_performance':
        return AppStrings.classroomPerformanceShort.tr();
      case 'homework_book':
        return AppStrings.homeworkBookShort.tr();
      case 'activity_book':
        return AppStrings.activityBookShort.tr();
      case 'weekly_review':
        return AppStrings.weeklyReviewShort.tr();
      case 'oral_tasks':
        return AppStrings.oralTasksShort.tr();
      case 'skill_tasks':
        return AppStrings.skillTasksShort.tr();
      case 'skills_performance':
        return AppStrings.skillsPerformanceShort.tr();
      case 'months_exam_average':
        return AppStrings.monthsExamAverageShort.tr();
      case 'attendance_and_diligence':
        return AppStrings.attendanceAndDiligenceShort.tr();
      case 'first_month_exam':
        return AppStrings.firstMonthExamShort.tr();
      case 'second_month_exam':
        return AppStrings.secondMonthExamShort.tr();
      default:
        return name;
    }
  }
}
