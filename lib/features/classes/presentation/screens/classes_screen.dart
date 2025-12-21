import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/presentation/controllers/classes_controller.dart';
import 'package:moalem/features/classes/presentation/models/add_class_form_data.dart';
import 'package:moalem/features/classes/presentation/screens/add_or_edit_class_dialog.dart';
import 'package:moalem/features/classes/presentation/screens/class_details_screen.dart';
import 'package:moalem/features/classes/presentation/widgets/class_card.dart';
import 'package:moalem/features/classes/presentation/widgets/classes_empty_state.dart';
import 'package:moalem/features/classes/presentation/widgets/evaluation_aspect_item.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/widgets/app_floating_action_button.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  Future<void> _showAddClassDialog(BuildContext context, WidgetRef ref) async {
    final result = await AddOrEditClassDialog.show(context);
    if (result != null && result.isValid) {
      ref
          .read(classesControllerProvider.notifier)
          .addClass(
            name: result.className!,
            grade: result.educationalStage!,
            subject: result.subject!,
            semester: result.semester!,
            school: result.school!,
          );
    }
  }

  Future<void> _showEditClassDialog(
    BuildContext context,
    WidgetRef ref,
    ClassEntity classEntity,
  ) async {
    final result = await AddOrEditClassDialog.show(
      context,
      initialData: ClassFormData.fromEntity(classEntity),
    );
    if (result != null && result.isValid) {
      ref
          .read(classesControllerProvider.notifier)
          .editClass(result.toEntity(classEntity));
    }
  }

  void _deleteClass(WidgetRef ref, String id) {
    ref.read(classesControllerProvider.notifier).deleteClass(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(classesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.classesTitle.tr())),
      body: classesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () =>
                    ref.read(classesControllerProvider.notifier).loadClasses(),
                child: Text(AppStrings.errorRetry.tr()),
              ),
            ],
          ),
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return ClassesEmptyState(
              onAddManually: () => _showAddClassDialog(context, ref),
              onAttachExcel: () {},
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 16.h),
                // Evaluation Aspects Section
                _buildEvaluationAspectsSection(),
                SizedBox(height: 16.h),
                // Divider
                Container(height: 1, color: AppColors.inactiveBorder),
                SizedBox(height: 24.h),
                // Classes List Section
                _buildClassesListSection(context, ref, classes),
                SizedBox(height: 100.h), // Space for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: classesState.maybeWhen(
        data: (classes) => classes.isNotEmpty
            ? AppFloatingActionButton(
                onPressed: () => _showAddClassDialog(context, ref),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildEvaluationAspectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.evaluationAspects.tr(),
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                AppStrings.viewAll.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Evaluation aspects horizontal list
        SizedBox(
          height: 100.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              EvaluationAspectItem(
                icon: AppAssets.icons.performanceMarks,
                label: AppStrings.classroomPerformance.tr(),
                onTap: () {},
              ),
              EvaluationAspectItem(
                icon: AppAssets.icons.homeworkMarks,
                label: AppStrings.homeworkBook.tr(),
                onTap: () {},
              ),
              EvaluationAspectItem(
                icon: AppAssets.icons.activitiesMarks,
                label: AppStrings.activityBook.tr(),
                onTap: () {},
              ),
              EvaluationAspectItem(
                icon: AppAssets.icons.weekMarks,
                label: AppStrings.weeklyReview.tr(),
                onTap: () {},
              ),
              EvaluationAspectItem(
                icon: AppAssets.icons.oralMarks,
                label: AppStrings.oralTasks.tr(),
                onTap: () {},
              ),
              EvaluationAspectItem(
                icon: AppAssets.icons.physicalMarks,
                label: AppStrings.skillTasks.tr(),
                onTap: () {},
              ),
              EvaluationAspectItem(
                icon: AppAssets.icons.attendanceMarks,
                label: AppStrings.attendanceAndDiligence.tr(),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassesListSection(
    BuildContext context,
    WidgetRef ref,
    List<ClassEntity> classes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          AppStrings.classroomsList.tr(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 16.h),
        // Classes List
        ...classes.map(
          (classEntity) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: ClassCard(
              id: classEntity.id,
              className: classEntity.name,
              section: classEntity.grade,
              studentCount: classEntity.studentsCount,
              onViewStudents: () =>
                  context.pushNewScreen(ClassDetailsScreen(id: classEntity.id)),
              onEdit: () => _showEditClassDialog(context, ref, classEntity),
              onDelete: () => _deleteClass(ref, classEntity.id),
            ),
          ),
        ),
      ],
    );
  }
}
