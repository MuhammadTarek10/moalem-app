import 'package:injectable/injectable.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';

@injectable
class EditClassUseCase {
  final ClassRepository _repository;

  EditClassUseCase(this._repository);

  Future<ClassEntity> call(ClassEntity classEntity) {
    return _repository.editClass(classEntity);
  }
}
