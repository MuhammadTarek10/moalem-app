import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_class_by_id_usecase.dart';

final classDetailsControllerProvider =
    StateNotifierProvider.family<
      ClassDetailsController,
      AsyncValue<ClassEntity?>,
      String
    >((ref, classId) {
      return ClassDetailsController(getIt<GetClassByIdUseCase>(), classId);
    });

class ClassDetailsController extends StateNotifier<AsyncValue<ClassEntity?>> {
  final GetClassByIdUseCase _getClassByIdUseCase;
  final String _classId;

  ClassDetailsController(this._getClassByIdUseCase, this._classId)
    : super(const AsyncValue.loading()) {
    loadClass();
  }

  Future<void> loadClass() async {
    state = const AsyncValue.loading();
    try {
      final classEntity = await _getClassByIdUseCase(_classId);
      state = AsyncValue.data(classEntity);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() {
    loadClass();
  }
}
