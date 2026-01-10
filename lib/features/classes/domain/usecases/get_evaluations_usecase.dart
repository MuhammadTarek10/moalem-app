import 'package:injectable/injectable.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';

@injectable
class GetEvaluationsUseCase {
  final ClassRepository _repository;

  GetEvaluationsUseCase(this._repository);

  Future<List<EvaluationEntity>> call() {
    return _repository.getEvaluations();
  }
}
