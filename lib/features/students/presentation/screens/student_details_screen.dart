import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/students/presentation/controllers/student_details_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/error_screen.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentDetailsControllerProvider(studentId));
    final controller = ref.read(
      studentDetailsControllerProvider(studentId).notifier,
    );

    return Container(
      child: state.data.when(
        loading: () => const SizedBox.shrink(),
        error: (error, _) => ErrorScreen(
          message: ErrorHandler.getErrorMessage(error),
          onRetry: () => controller.loadStudentDetails(),
        ),
        data: (details) {
          if (details == null) {
            return Center(child: Text(AppStrings.errorMessage.tr()));
          }

          // Auto-switch to monthly view for High School students
          if (details.classInfo.evaluationGroup == EvaluationGroup.high &&
              state.periodType == PeriodType.weekly) {
            Future.microtask(
              () => controller.changePeriodType(PeriodType.monthly),
            );
          }

          return Scaffold(
            appBar: AppBar(title: Text(details.classInfo.name)),
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(
                    context,
                    details.student.name,
                    details.student.number,
                    details.classInfo.name,
                  ),

                  // Filter Row
                  _buildFilterRow(context, state, controller),

                  // Main Content - Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          SizedBox(height: 16.h),

                          // Circular Progress
                          _buildProgressIndicator(
                            context,
                            controller.percentage.round(),
                          ),

                          SizedBox(height: 24.h),

                          // Score Items
                          ...details.evaluations.map((evaluation) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _buildScoreItem(
                                context,
                                _getEvaluationDisplayName(evaluation.name),
                                evaluation.maxScore,
                                controller.getDisplayScore(evaluation.id),
                                () => controller.incrementScore(
                                  evaluation.id,
                                  evaluation.maxScore,
                                ),
                                () => controller.decrementScore(evaluation.id),
                                evaluation.id,
                                controller,
                              ),
                            );
                          }),

                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  _buildFooter(context, controller, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String studentName,
    int studentNumber,
    String className,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                studentName,
                style: context.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${AppStrings.studentNumber.tr().replaceFirst('{}', studentNumber.toString())} - $className',
                style: context.bodySmall.copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    StudentDetailsState state,
    StudentDetailsController controller,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: Colors.white,
      child: Row(
        children: [
          // Period Number Dropdown
          Expanded(
            child: _buildDropdown(
              context,
              state.periodNumber.toString(),
              // Period Number Dropdown
              state.data.value?.classInfo.evaluationGroup ==
                      EvaluationGroup.high
                  ? [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(AppStrings.february.tr()),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(AppStrings.march.tr()),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(AppStrings.april.tr()),
                      ),
                    ]
                  : List.generate(18, (index) => index + 1)
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
          // Period Type Dropdown
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                state.data.value?.classInfo.evaluationGroup ==
                        EvaluationGroup.high
                    ? AppStrings.monthly.tr()
                    : _getPeriodTypeLabel(state.periodType),
                style: context.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Grades Label
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                AppStrings.grades.tr(),
                style: context.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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

  Widget _buildProgressIndicator(BuildContext context, int percentage) {
    final progressColor = percentage < 50 ? AppColors.error : AppColors.primary;
    final backgroundColor = percentage < 50
        ? AppColors.error.withValues(alpha: 0.2)
        : AppColors.primaryLighter;

    return SizedBox(
      width: 180.w,
      height: 180.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180.w,
            height: 180.w,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 12.w,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$percentage%',
            style: context.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(
    BuildContext context,
    String label,
    int maxScore,
    int currentScore,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
    String evaluationId,
    StudentDetailsController controller,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score controls
          Row(
            children: [
              _buildScoreButton(Icons.remove, onDecrement),
              GestureDetector(
                onTap: () => _showEditScoreDialog(
                  context,
                  controller,
                  evaluationId,
                  label,
                  currentScore,
                  maxScore,
                ),
                child: Container(
                  width: 50.w,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Text(
                    currentScore.toString(),
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ),
              _buildScoreButton(Icons.add, onIncrement),
              SizedBox(width: 8.w),
              // Max score button
              _buildScoreButton(
                Icons.done_all,
                () => controller.updateScore(evaluationId, maxScore),
                color: AppColors.primary.withValues(alpha: 0.1),
                iconColor: AppColors.primary,
              ),
            ],
          ),
          const Spacer(),
          // Label and max score
          Row(
            children: [
              Text(
                label,
                style: context.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '/$maxScore',
                style: context.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreButton(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: color ?? AppColors.primaryLighter,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textLight, size: 20.sp),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    StudentDetailsController controller,
    StudentDetailsState state,
  ) {
    final details = state.data.value;
    final maxScore = details?.maxPossibleScore ?? 0;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total score row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primaryLightest,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${controller.totalScore} / $maxScore',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  AppStrings.totalGrades.tr(),
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final success = await controller.saveChanges();
                      if (context.mounted) {
                        context.showSuccessSnackBar(
                          success
                              ? AppStrings.savedSuccessfully.tr()
                              : AppStrings.saveFailed.tr(),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: state.isSaving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      AppStrings.saveButton.tr(),
                      style: context.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditScoreDialog(
    BuildContext context,
    StudentDetailsController controller,
    String evaluationId,
    String evaluationName,
    int currentScore,
    int maxScore,
  ) {
    final textController = TextEditingController(text: currentScore.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(evaluationName),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppStrings.grades.tr(),
            hintText: '0 - $maxScore',
            border: const OutlineInputBorder(),
            suffix: Text('/ $maxScore'),
          ),
          onSubmitted: (value) {
            final score = int.tryParse(value);
            if (score != null && score >= 0 && score <= maxScore) {
              controller.updateScore(evaluationId, score);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancelButton.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final score = int.tryParse(textController.text);
              if (score != null && score >= 0 && score <= maxScore) {
                controller.updateScore(evaluationId, score);
                context.pop();
              } else {
                context.showErrorSnackBar(
                  'يجب أن تكون الدرجة بين 0 و $maxScore',
                );
              }
            },
            child: Text(AppStrings.saveButton.tr()),
          ),
        ],
      ),
    );
  }

  String _getPeriodTypeLabel(PeriodType type) {
    switch (type) {
      case PeriodType.weekly:
        return AppStrings.weekly.tr();
      case PeriodType.monthly:
        return AppStrings.monthly.tr();
      case PeriodType.semester:
        return AppStrings.semester.tr();
    }
  }

  String _getEvaluationDisplayName(String name) {
    switch (name) {
      case 'classroom_performance':
        return AppStrings.classroomPerformance.tr();
      case 'homework_book':
        return AppStrings.homeworkBook.tr();
      case 'activity_book':
        return AppStrings.activityBook.tr();
      case 'weekly_review':
        return AppStrings.weeklyReview.tr();
      case 'oral_tasks':
        return AppStrings.oralTasks.tr();
      case 'skill_tasks':
        return AppStrings.skillTasks.tr();
      case 'skills_performance':
        return AppStrings.skillsPerformance.tr();
      case 'months_exam_average':
        return AppStrings.monthsExamAverage.tr();
      case 'attendance_and_diligence':
        return AppStrings.attendanceAndDiligence.tr();
      case 'first_month_exam':
        return AppStrings.firstMonthExam.tr();
      case 'second_month_exam':
        return AppStrings.secondMonthExam.tr();
      case 'primary_homework':
        return AppStrings.primaryHomework.tr();
      case 'primary_activity':
        return AppStrings.primaryActivity.tr();
      case 'primary_weekly':
        return AppStrings.primaryWeekly.tr();
      case 'primary_performance':
        return AppStrings.primaryPerformance.tr();
      case 'primary_attendance':
        return AppStrings.primaryAttendance.tr();
      case 'weekly_review_w1':
        return AppStrings.week1Label.tr();
      case 'weekly_review_w2':
        return AppStrings.week2Label.tr();
      case 'weekly_review_w3':
        return AppStrings.week3Label.tr();
      case 'weekly_review_w4':
        return AppStrings.week4Label.tr();
      default:
        return name;
    }
  }
}
