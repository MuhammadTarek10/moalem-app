import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/entities/failure.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';
import 'package:uuid/uuid.dart';

@injectable
class AddClassUseCase {
  final ClassRepository _repository;

  AddClassUseCase(this._repository);

  Future<Either<Failure, ClassEntity>> call({
    required String name,
    required String grade,
    required String subject,
    required String semester,
    required String school,
    required EvaluationGroup evaluationGroup,
  }) async {
    try {
      final classes = await _repository.getClasses();
      if (classes.length >= 15) {
        return const Left(ClassLimitFailure());
      }

      final classEntity = ClassEntity(
        id: const Uuid().v4(),
        name: name,
        grade: grade,
        subject: subject,
        semester: semester,
        school: school,
        evaluationGroup: evaluationGroup,
        createdAt: DateTime.now(),
      );
      final result = await _repository.addClass(classEntity);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
