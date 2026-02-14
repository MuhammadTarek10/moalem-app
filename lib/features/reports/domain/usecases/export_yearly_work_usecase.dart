import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/reports/domain/entities/excel_export_entity.dart';
import 'package:moalem/features/reports/domain/repositories/excel_export_repository.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:uuid/uuid.dart';

/// Use case for exporting yearly work reports
@injectable
class ExportYearlyWorkUseCase {
  final ExcelExportRepository _repository;

  ExportYearlyWorkUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required ExportYearlyWorkParams params,
  }) async {
    try {
      final entity = _mapParamsToEntity(params);

      // Validate export data
      final preview = await _repository.previewExport(exportData: entity);
      if (!preview.isValid) {
        return Left(ValidationFailure(preview.missingData.join(', ')));
      }

      final filePath = await _repository.exportYearlyWork(exportData: entity);

      return Right(filePath);
    } on ExcelExportException catch (e) {
      return Left(ExcelExportFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  ExcelExportEntity _mapParamsToEntity(ExportYearlyWorkParams params) {
    return ExcelExportEntity(
      id: const Uuid().v4(),
      exportType: ExportType.yearlyWork,
      stage: _mapEvaluationGroupToStage(params.classEntity.evaluationGroup),
      schoolInfo: SchoolInfo(
        governorate: params.governorate,
        administration: params.administration,
        schoolName: params.classEntity.school,
      ),
      classInfo: ClassInfo(
        className: params.classEntity.name,
        grade: params.classEntity.grade,
        subject: params.classEntity.subject,
        section: null,
      ),
      students: params.studentsData.map((s) => _mapStudentData(s)).toList(),
      options: ExportOptions(
        includeSemesterAverage: params.includeSemesterAverage,
        includeMonthlyExams: params.includeMonthlyExams,
        exportDate: DateTime.now(),
      ),
      createdAt: DateTime.now(),
    );
  }

  StudentExportData _mapStudentData(StudentYearlyWorkData data) {
    return StudentExportData(
      studentId: data.student.id,
      name: data.student.name,
      number: data.student.number,
      weeklyScores: data.weeklyScores,
      weeklyTotals: data.weeklyTotals,
      monthlyExamScores: data.monthlyExamScores,
      weeklyAttendance: null,
    );
  }

  EducationalStage _mapEvaluationGroupToStage(EvaluationGroup group) {
    switch (group) {
      case EvaluationGroup.prePrimary:
        return EducationalStage.prePrimary;
      case EvaluationGroup.primary:
        return EducationalStage.primary;
      case EvaluationGroup.secondary:
        return EducationalStage.preparatory;
      case EvaluationGroup.high:
        return EducationalStage.secondary;
    }
  }
}

/// Parameters for exporting yearly work
class ExportYearlyWorkParams {
  final ClassEntity classEntity;
  final String governorate;
  final String administration;
  final List<StudentYearlyWorkData> studentsData;
  final bool includeSemesterAverage;
  final bool includeMonthlyExams;

  const ExportYearlyWorkParams({
    required this.classEntity,
    required this.governorate,
    required this.administration,
    required this.studentsData,
    this.includeSemesterAverage = true,
    this.includeMonthlyExams = true,
  });
}

/// Student data for yearly work export
class StudentYearlyWorkData {
  final StudentEntity student;
  final Map<int, Map<String, int>> weeklyScores; // week -> evalId -> score
  final Map<int, int> weeklyTotals; // week -> total
  final Map<String, int>? monthlyExamScores; // examId -> score

  const StudentYearlyWorkData({
    required this.student,
    required this.weeklyScores,
    required this.weeklyTotals,
    this.monthlyExamScores,
  });
}

/// Base failure class
abstract class Failure {
  final String message;

  const Failure(this.message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Excel export failure
class ExcelExportFailure extends Failure {
  const ExcelExportFailure(super.message);
}

/// Unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// Excel export exception
class ExcelExportException implements Exception {
  final String message;

  ExcelExportException(this.message);

  @override
  String toString() => message;
}
