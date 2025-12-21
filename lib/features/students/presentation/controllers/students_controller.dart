import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/usecases/add_student_usecase.dart';
import 'package:moalem/features/students/domain/usecases/delete_student_usecase.dart';
import 'package:moalem/features/students/domain/usecases/edit_student_usecase.dart';
import 'package:moalem/features/students/domain/usecases/get_students_usecase.dart';

final studentsControllerProvider =
    StateNotifierProvider.family<
      StudentsController,
      AsyncValue<List<StudentEntity>>,
      String
    >((ref, classId) {
      return StudentsController(
        getIt<GetStudentsUseCase>(),
        getIt<AddStudentUseCase>(),
        getIt<EditStudentUseCase>(),
        getIt<DeleteStudentUseCase>(),
        classId,
      );
    });

class StudentsController
    extends StateNotifier<AsyncValue<List<StudentEntity>>> {
  final GetStudentsUseCase _getStudentsUseCase;
  final AddStudentUseCase _addStudentUseCase;
  final EditStudentUseCase _editStudentUseCase;
  final DeleteStudentUseCase _deleteStudentUseCase;
  final String _classId;

  StudentsController(
    this._getStudentsUseCase,
    this._addStudentUseCase,
    this._editStudentUseCase,
    this._deleteStudentUseCase,
    this._classId,
  ) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final students = await _getStudentsUseCase(_classId);
      state = AsyncValue.data(students);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addStudent({required String name, required int number}) async {
    try {
      final newStudent = await _addStudentUseCase(
        classId: _classId,
        name: name,
        number: number,
      );

      state.whenData((students) {
        final updatedList = [...students, newStudent];
        updatedList.sort((a, b) => a.number.compareTo(b.number));
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editStudent(StudentEntity student) async {
    try {
      final updatedStudent = await _editStudentUseCase(student);

      state.whenData((students) {
        final updatedList = students.map((s) {
          return s.id == updatedStudent.id ? updatedStudent : s;
        }).toList();
        updatedList.sort((a, b) => a.number.compareTo(b.number));
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _deleteStudentUseCase(id);

      state.whenData((students) {
        final updatedList = students.where((s) => s.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
