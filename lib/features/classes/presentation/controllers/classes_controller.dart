import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/usecases/add_class_usecase.dart';
import 'package:moalem/features/classes/domain/usecases/delete_class_usecase.dart';
import 'package:moalem/features/classes/domain/usecases/edit_class_usecase.dart';
import 'package:moalem/features/classes/domain/usecases/get_classes_usecase.dart';

final classesControllerProvider =
    StateNotifierProvider<ClassesController, AsyncValue<List<ClassEntity>>>((
      ref,
    ) {
      return ClassesController(
        getIt<GetClassesUseCase>(),
        getIt<AddClassUseCase>(),
        getIt<EditClassUseCase>(),
        getIt<DeleteClassUseCase>(),
      );
    });

class ClassesController extends StateNotifier<AsyncValue<List<ClassEntity>>> {
  final GetClassesUseCase _getClassesUseCase;
  final AddClassUseCase _addClassUseCase;
  final EditClassUseCase _editClassUseCase;
  final DeleteClassUseCase _deleteClassUseCase;

  ClassesController(
    this._getClassesUseCase,
    this._addClassUseCase,
    this._editClassUseCase,
    this._deleteClassUseCase,
  ) : super(const AsyncValue.loading()) {
    loadClasses();
  }

  Future<void> loadClasses() async {
    state = const AsyncValue.loading();
    try {
      final classes = await _getClassesUseCase();
      state = AsyncValue.data(classes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addClass({
    required String name,
    required String stage,
    required String grade,
    required String subject,
    required String semester,
    required String school,
    EvaluationGroup evaluationGroup = EvaluationGroup.prePrimary,
  }) async {
    try {
      final newClass = await _addClassUseCase(
        name: name,
        stage: stage,
        grade: grade,
        subject: subject,
        semester: semester,
        school: school,
        evaluationGroup: evaluationGroup,
      );

      state.whenData((classes) {
        state = AsyncValue.data([newClass, ...classes]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editClass(ClassEntity classEntity) async {
    try {
      final updatedClass = await _editClassUseCase(classEntity);

      state.whenData((classes) {
        final updatedList = classes.map((c) {
          return c.id == updatedClass.id ? updatedClass : c;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      await _deleteClassUseCase(id);

      state.whenData((classes) {
        final updatedList = classes.where((c) => c.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reloadClasses() async {
    try {
      final classes = await _getClassesUseCase();
      state = AsyncValue.data(classes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
