import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_input_entity.dart';
import 'package:moalem/features/students/presentation/controllers/bulk_score_entry_controller.dart';
import 'package:moalem/features/students/presentation/widgets/score_entry_dialog.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/loading_screen.dart';
import 'package:moalem/shared/widgets/qr_scanner_screen.dart';

class BulkScoreEntryScreen extends ConsumerStatefulWidget {
  final String classId;

  const BulkScoreEntryScreen({super.key, required this.classId});

  @override
  ConsumerState<BulkScoreEntryScreen> createState() =>
      _BulkScoreEntryScreenState();
}

class _BulkScoreEntryScreenState extends ConsumerState<BulkScoreEntryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkScoreEntryControllerProvider(widget.classId));
    final controller = ref.read(
      bulkScoreEntryControllerProvider(widget.classId).notifier,
    );

    if (state.isLoading && state.classInfo == null) {
      return const LoadingScreen();
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.bulkScoreEntry.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.error!),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => controller.loadClassData(widget.classId),
                child: Text(AppStrings.errorRetry.tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (state.classInfo == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.bulkScoreEntry.tr())),
        body: Center(child: Text(AppStrings.noData.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.classInfo!.name),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and filters section
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Column(
              children: [
                // Search bar with icons
                Row(
                  children: [
                    // Search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textAlign: TextAlign.right,
                        onChanged: (value) => controller.setSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchStudents.tr(),
                          hintStyle: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14.sp,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppColors.textLight.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppColors.textLight.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textLight,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // QR icon
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.textLight.withValues(alpha: 0.2),
                        ),
                      ),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/scan.svg',
                          width: 24.w,
                          height: 24.h,
                        ),
                        onPressed: () async {
                          final qrResult = await Navigator.push<dynamic>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QrScannerScreen(
                                isMultiScan: true,
                                onCodeScanned: (code) async {
                                  final student = await controller
                                      .handleQrScanned(code);
                                  return student?.name;
                                },
                              ),
                            ),
                          );

                          if (qrResult is List<String> &&
                              qrResult.isNotEmpty &&
                              context.mounted) {
                            final students = await controller
                                .handleMultipleQrScanned(qrResult);

                            if (students.isNotEmpty && context.mounted) {
                              final score = await showDialog<int>(
                                context: context,
                                builder: (context) => ScoreEntryDialog(
                                  studentName: students.length > 1
                                      ? '${students.length} طلاب'
                                      : students.first.name,
                                  maxScore: state.currentMaxScore ?? 0,
                                ),
                              );

                              if (score != null) {
                                await controller.updateMultipleStudentsScores(
                                  students.map((e) => e.id).toList(),
                                  score,
                                );
                                if (context.mounted) {
                                  context.showSuccessSnackBar(
                                    AppStrings.scoresUpdated.tr(),
                                  );
                                }
                              }
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No students found in this class',
                                    textAlign: TextAlign.center,
                                  ).tr(),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Calendar icon
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.textLight.withValues(alpha: 0.2),
                        ),
                      ),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          AppAssets.icons.calender,
                          width: 24.w,
                          height: 24.h,
                        ),
                        onPressed: () {
                          // Calendar functionality can be added here
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Evaluation dropdown
                _buildDropdown<EvaluationEntity>(
                  value: state.selectedEvaluation,
                  items: state.availableEvaluations,
                  onChanged: (value) {
                    if (value != null) controller.selectEvaluation(value);
                  },
                  displayText: (e) => _getEvaluationDisplayName(e.name),
                  hint: AppStrings.selectEvaluation.tr(),
                ),
                SizedBox(height: 12.h),
                // Period dropdowns
                Row(
                  children: [
                    // Period number dropdown
                    Expanded(
                      child: _buildDropdown<int>(
                        value: state.periodNumber,
                        items: List.generate(12, (i) => i + 1),
                        onChanged: (value) {
                          if (value != null) {
                            controller.changePeriodNumber(value);
                          }
                        },
                        displayText: (n) => n.toString(),
                        hint: AppStrings.selectPeriod.tr(),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Period type dropdown (fixed to weekly for now)
                    Expanded(
                      child: _buildDropdown<PeriodType>(
                        value: state.periodType,
                        items: const [PeriodType.weekly],
                        onChanged: (value) {
                          if (value != null) controller.changePeriodType(value);
                        },
                        displayText: (type) => _getPeriodTypeText(type),
                        hint: '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score selector and select all section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Select all button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.toggleSelectAll(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: Text(
                      state.allSelected
                          ? AppStrings.deselectAll.tr()
                          : AppStrings.selectAll.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // Score controls
                _buildScoreControls(controller, state),
              ],
            ),
          ),
          // Students list
          Expanded(
            child: state.filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.noStudentsTitle.tr(),
                      style: context.bodyLarge.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: state.filteredStudents.length,
                    itemBuilder: (context, index) {
                      final studentInput = state.filteredStudents[index];
                      return _buildStudentScoreRow(
                        studentInput,
                        controller,
                        state.currentMaxScore ?? 0,
                      );
                    },
                  ),
          ),
          // Save button
          if (state.selectedCount > 0)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () =>
                    _showSaveConfirmationDialog(context, controller, state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  AppStrings.saveButton.tr(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
    required String Function(T) displayText,
    required String hint,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: AppColors.textLight, fontSize: 14.sp),
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                displayText(item),
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.right,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildScoreControls(
    BulkScoreEntryController controller,
    BulkScoreEntryState state,
  ) {
    return Row(
      children: [
        // Increment button
        _buildScoreButton(
          icon: Icons.add,
          onPressed: () => controller.setMaxScoreForSelected(),
          color: AppColors.primary.withValues(alpha: 0.1),
          iconColor: AppColors.primary,
        ),
        SizedBox(width: 8.w),
        // Max score display
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '${state.currentMaxScore ?? 0}',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // Decrement button
        _buildScoreButton(
          icon: Icons.add,
          onPressed: () => controller.setMaxScoreForSelected(),
          color: AppColors.primary.withValues(alpha: 0.1),
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStudentScoreRow(
    StudentScoreInput studentInput,
    BulkScoreEntryController controller,
    int maxScore,
  ) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.studentDetailsPath(studentInput.student.id)),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: studentInput.isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: studentInput.isSelected
                ? AppColors.primary
                : AppColors.textLight.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Score controls
            Row(
              children: [
                // Decrement
                _buildScoreButton(
                  icon: Icons.remove,
                  onPressed: studentInput.currentScore > 0
                      ? () => controller.decrementScore(studentInput.student.id)
                      : null,
                  color: Colors.white,
                  iconColor: AppColors.textLight,
                ),
                SizedBox(width: 8.w),
                // Score display
                GestureDetector(
                  onTap: () => _showEditScoreDialog(
                    context,
                    controller,
                    studentInput.student.id,
                    studentInput.currentScore,
                    maxScore,
                  ),
                  child: Container(
                    width: 40.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${studentInput.currentScore}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Increment
                _buildScoreButton(
                  icon: Icons.add,
                  onPressed: studentInput.currentScore < maxScore
                      ? () => controller.incrementScore(studentInput.student.id)
                      : null,
                  color: Colors.white,
                  iconColor: AppColors.textLight,
                ),
              ],
            ),
            SizedBox(width: 12.w),
            // Student name
            Expanded(
              child: Text(
                studentInput.student.name,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMain,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Checkbox
            Checkbox(
              value: studentInput.isSelected,
              onChanged: (_) =>
                  controller.toggleStudentSelection(studentInput.student.id),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18.w),
        onPressed: onPressed,
        color: iconColor,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showEditScoreDialog(
    BuildContext context,
    BulkScoreEntryController controller,
    String studentId,
    int currentScore,
    int maxScore,
  ) {
    final textController = TextEditingController(text: currentScore.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.grades.tr(), textAlign: TextAlign.right),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0 - $maxScore',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppStrings.cancelButton.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final newScore = int.tryParse(textController.text) ?? 0;
              controller.setScore(studentId, newScore);
              context.pop();
            },
            child: Text(AppStrings.saveButton.tr()),
          ),
        ],
      ),
    );
  }

  void _showSaveConfirmationDialog(
    BuildContext context,
    BulkScoreEntryController controller,
    BulkScoreEntryState state,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.confirmSaveScores.tr(),
          textAlign: TextAlign.right,
        ),
        content: Text(
          AppStrings.saveScoresMessage.tr(
            args: [state.selectedCount.toString()],
          ),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppStrings.cancelButton.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              context.pop();
              await controller.saveSelectedScores();
              if (context.mounted && state.error == null) {
                context.showSuccessSnackBar(AppStrings.scoresUpdated.tr());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              AppStrings.saveButton.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
      default:
        return name;
    }
  }

  String _getPeriodTypeText(PeriodType type) {
    switch (type) {
      case PeriodType.weekly:
        return AppStrings.weekly.tr();
      case PeriodType.monthly:
        return AppStrings.monthly.tr();
      case PeriodType.semester:
        return AppStrings.semester.tr();
    }
  }
}
