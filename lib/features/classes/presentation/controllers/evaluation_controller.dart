import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_evaluations_usecase.dart';

final evaluationControllerProvider =
    StateNotifierProvider<
      EvaluationController,
      AsyncValue<List<EvaluationEntity>>
    >((ref) {
      return EvaluationController(getIt<GetEvaluationsUseCase>());
    });

class EvaluationController
    extends StateNotifier<AsyncValue<List<EvaluationEntity>>> {
  final GetEvaluationsUseCase _getEvaluationsUseCase;

  EvaluationController(this._getEvaluationsUseCase)
    : super(const AsyncValue.loading()) {
    loadEvaluations();
  }

  Future<void> loadEvaluations() async {
    state = const AsyncValue.loading();
    try {
      final evaluations = await _getEvaluationsUseCase();
      state = AsyncValue.data(evaluations);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
