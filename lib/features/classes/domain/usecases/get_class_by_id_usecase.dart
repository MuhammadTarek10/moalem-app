import 'package:injectable/injectable.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';

@injectable
class GetClassByIdUseCase {
  final ClassRepository _repository;

  GetClassByIdUseCase(this._repository);

  Future<ClassEntity?> call(String id) {
    return _repository.getClassById(id);
  }
}
