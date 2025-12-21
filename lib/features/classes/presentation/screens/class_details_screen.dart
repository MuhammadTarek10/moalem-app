import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/classes/presentation/controllers/class_details_controller.dart';
import 'package:moalem/features/classes/presentation/models/student_form_data.dart';
import 'package:moalem/features/classes/presentation/screens/add_or_edit_student_dialog.dart';
import 'package:moalem/features/classes/presentation/widgets/student_card.dart';
import 'package:moalem/features/classes/presentation/widgets/students_empty_state.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/presentation/controllers/students_controller.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/screens/loading_screen.dart';
import 'package:moalem/shared/widgets/app_floating_action_button.dart';

class ClassDetailsScreen extends ConsumerWidget {
  final String id;

  const ClassDetailsScreen({super.key, required this.id});

  Future<void> _showAddStudentDialog(
    BuildContext context,
    WidgetRef ref,
    int studentsCount,
  ) async {
    final result = await AddOrEditStudentDialog.show(
      context,
      studentsCount: studentsCount,
    );
    if (result != null && result.isValid) {
      ref
          .read(studentsControllerProvider(id).notifier)
          .addStudent(name: result.name!, number: result.number!);
    }
  }

  Future<void> _showEditStudentDialog(
    BuildContext context,
    WidgetRef ref,
    StudentEntity student,
    int studentsCount,
  ) async {
    final result = await AddOrEditStudentDialog.show(
      context,
      initialData: StudentFormData.fromEntity(student),
      studentsCount: studentsCount,
    );
    if (result != null && result.isValid) {
      ref
          .read(studentsControllerProvider(id).notifier)
          .editStudent(result.toEntity(student));
    }
  }

  void _deleteStudent(WidgetRef ref, String studentId) {
    ref.read(studentsControllerProvider(id).notifier).deleteStudent(studentId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classState = ref.watch(classDetailsControllerProvider(id));
    final studentsState = ref.watch(studentsControllerProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: classState.maybeWhen(
          data: (classEntity) => Text(classEntity?.name ?? ''),
          orElse: () => const Text(''),
        ),
      ),
      body: classState.when(
        loading: () => const LoadingScreen(),
        error: (error, _) => ErrorScreen(
          message: ErrorHandler.getErrorMessage(error),
          onRetry: () =>
              ref.read(classDetailsControllerProvider(id).notifier).refresh(),
        ),
        data: (classEntity) {
          if (classEntity == null) {
            return Center(child: Text(AppStrings.errorMessage.tr()));
          }

          return studentsState.when(
            loading: () => const LoadingScreen(),
            error: (error, _) => ErrorScreen(
              message: ErrorHandler.getErrorMessage(error),
              onRetry: () => ref
                  .read(studentsControllerProvider(id).notifier)
                  .loadStudents(),
            ),
            data: (students) {
              if (students.isEmpty) {
                return StudentsEmptyState(
                  onAddManually: () =>
                      _showAddStudentDialog(context, ref, students.length),
                  onAttachExcel: () {},
                );
              }

              // Display students list
              return ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: students.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return StudentCard(
                    student: student,
                    onEdit: () => _showEditStudentDialog(
                      context,
                      ref,
                      student,
                      students.length,
                    ),
                    onDelete: () => _deleteStudent(ref, student.id),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: studentsState.maybeWhen(
        data: (students) => AppFloatingActionButton(
          onPressed: () => _showAddStudentDialog(context, ref, students.length),
        ),
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
