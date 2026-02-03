import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';
import 'package:uuid/uuid.dart';

@injectable
class AddClassUseCase {
  final ClassRepository _repository;

  AddClassUseCase(this._repository);

  Future<ClassEntity> call({
    required String name,
    required String stage,
    required String grade,
    required String subject,
    required String semester,
    required String school,
    required EvaluationGroup evaluationGroup,
  }) {
    final classEntity = ClassEntity(
      id: const Uuid().v4(),
      name: name,
      stage: stage,
      grade: grade,
      subject: subject,
      semester: semester,
      school: school,
      evaluationGroup: evaluationGroup,
      createdAt: DateTime.now(),
    );
    return _repository.addClass(classEntity);
  }
}
