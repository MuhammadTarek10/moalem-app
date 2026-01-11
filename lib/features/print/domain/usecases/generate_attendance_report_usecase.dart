import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart' as app_enums;
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class GenerateAttendanceReportUseCase {
  final StudentRepository _studentRepository;
  final ClassRepository _classRepository;
  final UserRepository _userRepository;

  GenerateAttendanceReportUseCase(
    this._studentRepository,
    this._classRepository,
    this._userRepository,
  );

  Future<PrintDataEntity?> call(
    String classId,
    app_enums.PeriodType periodType,
    int periodNumber,
  ) async {
    // Get class info
    final classEntity = await _classRepository.getClassById(classId);
    if (classEntity == null) return null;

    // Get user profile for governorate and administration
    final user = await _userRepository.getUser();
    final governorate = user.governorate ?? '';
    final administration = user.educationalAdministration ?? '';

    // Get all students in the class
    final students = await _studentRepository.getStudentsByClassId(classId);

    // Get attendance for each student
    final List<StudentPrintData> studentsData = [];

    for (final student in students) {
      final studentDetails = await _studentRepository
          .getStudentDetailsWithScores(student.id, periodType, periodNumber);

      if (studentDetails != null) {
        // For attendance, we'll use the attendance evaluation
        final attendanceStatus = studentDetails.attendanceStatus;

        // Create a simple attendance map for this period
        final attendance = <String, AttendanceStatus>{};
        if (attendanceStatus != null) {
          final statusKey = 'period_$periodNumber';
          attendance[statusKey] = _convertAttendanceStatus(attendanceStatus);
        }

        studentsData.add(
          StudentPrintData(
            student: student,
            scores: {}, // No scores for attendance report
            attendance: attendance,
            totalScore: 0,
            maxPossibleScore: 0,
          ),
        );
      }
    }

    return PrintDataEntity(
      printType: PrintType.attendance,
      classEntity: classEntity,
      governorate: governorate,
      administration: administration,
      periodType: periodType,
      periodNumber: periodNumber,
      studentsData: studentsData,
      evaluations: null, // No evaluations for attendance report
    );
  }

  AttendanceStatus _convertAttendanceStatus(app_enums.AttendanceStatus status) {
    switch (status) {
      case app_enums.AttendanceStatus.present:
        return AttendanceStatus.present;
      case app_enums.AttendanceStatus.absent:
        return AttendanceStatus.absent;
      case app_enums.AttendanceStatus.excused:
        return AttendanceStatus.excused;
    }
  }
}
