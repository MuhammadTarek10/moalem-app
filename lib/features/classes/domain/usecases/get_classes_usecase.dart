import 'package:injectable/injectable.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';

@injectable
class GetClassesUseCase {
  final ClassRepository _repository;

  GetClassesUseCase(this._repository);

  Future<List<ClassEntity>> call() {
    return _repository.getClasses();
  }
}
