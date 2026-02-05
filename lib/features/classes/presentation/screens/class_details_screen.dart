import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/features/classes/presentation/controllers/class_details_controller.dart';
import 'package:moalem/features/classes/presentation/models/student_form_data.dart';
import 'package:moalem/features/classes/presentation/screens/add_or_edit_student_dialog.dart';
import 'package:moalem/features/classes/presentation/widgets/student_card.dart';
import 'package:moalem/features/classes/presentation/widgets/students_empty_state.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/presentation/controllers/students_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/screens/loading_screen.dart';
import 'package:moalem/shared/widgets/app_floating_action_button.dart';

class ClassDetailsScreen extends ConsumerStatefulWidget {
  final String id;

  const ClassDetailsScreen({super.key, required this.id});

  @override
  ConsumerState<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends ConsumerState<ClassDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentEntity> _filterStudents(List<StudentEntity> students) {
    if (_searchQuery.isEmpty) return students;
    return students
        .where(
          (student) =>
              student.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _showAddStudentDialog(
    BuildContext context,
    int studentsCount,
  ) async {
    final result = await AddOrEditStudentDialog.show(
      context,
      studentsCount: studentsCount,
    );
    if (result != null && result.isValid) {
      ref
          .read(studentsControllerProvider(widget.id).notifier)
          .addStudent(name: result.name!, number: result.number!);
    }
  }

  Future<void> _showEditStudentDialog(
    BuildContext context,
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
          .read(studentsControllerProvider(widget.id).notifier)
          .editStudent(result.toEntity(student));
    }
  }

  void _deleteStudent(String studentId) {
    ref
        .read(studentsControllerProvider(widget.id).notifier)
        .deleteStudent(studentId);
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classDetailsControllerProvider(widget.id));
    final studentsState = ref.watch(studentsControllerProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: classState.maybeWhen(
          data: (classEntity) => Text(classEntity?.name ?? ''),
          orElse: () => const Text(''),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              context.push('${AppRoutes.reports}?classId=${widget.id}');
            },
            tooltip: AppStrings.viewReports.tr(),
          ),
        ],
      ),
      body: classState.when(
        loading: () => const LoadingScreen(),
        error: (error, _) => ErrorScreen(
          message: ErrorHandler.getErrorMessage(error),
          onRetry: () => ref
              .read(classDetailsControllerProvider(widget.id).notifier)
              .refresh(),
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
                  .read(studentsControllerProvider(widget.id).notifier)
                  .loadStudents(),
            ),
            data: (students) {
              if (students.isEmpty) {
                return StudentsEmptyState(
                  onAddManually: () =>
                      _showAddStudentDialog(context, students.length),
                  onAttachExcel: () {},
                );
              }

              final filteredStudents = _filterStudents(students);

              // Display students list with search bar
              return Column(
                children: [
                  // Search bar
                  Container(
                    padding: EdgeInsets.all(16.w),
                    color: Colors.white,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'بحث عن طالب ..',
                        hintStyle: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textLight,
                          size: 24.sp,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.textLight,
                                  size: 20.sp,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),
                  // Students list
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16.sp,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.all(16.w),
                            itemCount: filteredStudents.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 8.h),
                            itemBuilder: (context, index) {
                              final student = filteredStudents[index];
                              return StudentCard(
                                student: student,
                                index: index,
                                onEdit: () => _showEditStudentDialog(
                                  context,
                                  student,
                                  students.length,
                                ),
                                onDelete: () => _deleteStudent(student.id),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: studentsState.maybeWhen(
        data: (students) => AppFloatingActionButton(
          onPressed: () => _showAddStudentDialog(context, students.length),
        ),
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
