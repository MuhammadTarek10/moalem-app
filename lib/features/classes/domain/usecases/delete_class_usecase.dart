import 'package:injectable/injectable.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';

@injectable
class DeleteClassUseCase {
  final ClassRepository _repository;

  DeleteClassUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteClass(id);
  }
}
