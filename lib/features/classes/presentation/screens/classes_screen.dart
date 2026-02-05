import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/extensions/evaluation_group_extensions.dart'; // Added
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/presentation/controllers/classes_controller.dart';
import 'package:moalem/features/classes/presentation/models/add_class_form_data.dart';
import 'package:moalem/features/classes/presentation/screens/add_or_edit_class_dialog.dart';
import 'package:moalem/features/classes/presentation/screens/class_details_screen.dart';
import 'package:moalem/features/classes/presentation/widgets/class_card.dart';
import 'package:moalem/features/classes/presentation/widgets/classes_empty_state.dart';
import 'package:moalem/features/students/presentation/screens/bulk_score_entry_screen.dart';
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
            // stage removed
            grade: result.gradeLevel!,
            subject: result.subject!,
            semester: result.semester!,
            school: result.school!,
            evaluationGroup: result.evaluationGroup!,
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
              stage: classEntity.evaluationGroup.stageName, // Use extension
              grade: classEntity.grade,
              subject: classEntity.subject,
              studentCount: classEntity.studentsCount,
              onViewStudents: () =>
                  context.pushNewScreen(ClassDetailsScreen(id: classEntity.id)),
              onAddScores: () => context.pushNewScreen(
                BulkScoreEntryScreen(classId: classEntity.id),
              ),
              onAddAttendance: () => context.push(
                AppRoutes.attendanceEntryPath(classId: classEntity.id),
              ),
              onEdit: () => _showEditClassDialog(context, ref, classEntity),
              onDelete: () => _deleteClass(ref, classEntity.id),
            ),
          ),
        ),
      ],
    );
  }
}
