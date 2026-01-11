import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
import 'package:moalem/features/attendance/domain/usecases/get_weekly_attendance_usecase.dart';
import 'package:moalem/features/attendance/domain/usecases/save_attendance_usecase.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_class_by_id_usecase.dart';
import 'package:moalem/features/classes/domain/usecases/get_classes_usecase.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';

/// Input entity for attendance entry
class StudentAttendanceInput {
  final StudentEntity student;
  final Map<DateTime, AttendanceStatus> dailyStatus; // date -> status
  final bool hasChanges;

  const StudentAttendanceInput({
    required this.student,
    required this.dailyStatus,
    this.hasChanges = false,
  });

  StudentAttendanceInput copyWith({
    StudentEntity? student,
    Map<DateTime, AttendanceStatus>? dailyStatus,
    bool? hasChanges,
  }) {
    return StudentAttendanceInput(
      student: student ?? this.student,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }

  /// Get status for a specific date
  AttendanceStatus? getStatusForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyStatus[normalizedDate];
  }
}

/// State for attendance entry screen
class AttendanceEntryState {
  final List<ClassEntity> classes;
  final ClassEntity? selectedClass;
  final DateTime weekStartDate;
  final DateTime selectedDay;
  final List<StudentAttendanceInput> students;
  final String searchQuery;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  AttendanceEntryState({
    this.classes = const [],
    this.selectedClass,
    DateTime? weekStartDate,
    DateTime? selectedDay,
    this.students = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  })  : weekStartDate = weekStartDate ?? WeekHelper.getWeekStart(DateTime.now()),
        selectedDay = selectedDay ?? WeekHelper.getWeekStart(DateTime.now());

  AttendanceEntryState copyWith({
    List<ClassEntity>? classes,
    ClassEntity? selectedClass,
    DateTime? weekStartDate,
    DateTime? selectedDay,
    List<StudentAttendanceInput>? students,
    String? searchQuery,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AttendanceEntryState(
      classes: classes ?? this.classes,
      selectedClass: selectedClass ?? this.selectedClass,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      selectedDay: selectedDay ?? this.selectedDay,
      students: students ?? this.students,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearMessages ? null : (error ?? this.error),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  /// Get week days (Sat-Thu)
  List<DateTime> get weekDays => WeekHelper.getWeekDays(weekStartDate);

  /// Get week end date
  DateTime get weekEndDate => WeekHelper.getWeekEnd(weekStartDate);

  /// Get filtered students by search
  List<StudentAttendanceInput> get filteredStudents {
    if (searchQuery.isEmpty) return students;
    return students
        .where(
          (s) => s.student.name.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => students.any((s) => s.hasChanges);

  /// Get count of students with attendance recorded for selected day
  int get recordedCount {
    return students.where((s) => s.getStatusForDate(selectedDay) != null).length;
  }
}

@injectable
class AttendanceEntryController extends StateNotifier<AttendanceEntryState> {
  final GetClassesUseCase _getClassesUseCase;
  final GetClassByIdUseCase _getClassByIdUseCase;
  final GetWeeklyAttendanceUseCase _getWeeklyAttendanceUseCase;
  final SaveAttendanceUseCase _saveAttendanceUseCase;

  AttendanceEntryController(
    this._getClassesUseCase,
    this._getClassByIdUseCase,
    this._getWeeklyAttendanceUseCase,
    this._saveAttendanceUseCase,
  ) : super(AttendanceEntryState());

  /// Initialize by loading classes
  Future<void> initialize({String? classId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final classes = await _getClassesUseCase();
      ClassEntity? selectedClass;

      if (classId != null && classId.isNotEmpty) {
        selectedClass = await _getClassByIdUseCase(classId);
      } else if (classes.isNotEmpty) {
        selectedClass = classes.first;
      }

      state = state.copyWith(
        classes: classes,
        selectedClass: selectedClass,
        isLoading: false,
      );

      if (selectedClass != null) {
        await loadAttendanceData();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select a class
  Future<void> selectClass(String classId) async {
    final classEntity = await _getClassByIdUseCase(classId);
    if (classEntity != null) {
      state = state.copyWith(selectedClass: classEntity);
      await loadAttendanceData();
    }
  }

  /// Change the selected week
  Future<void> changeWeek(DateTime date) async {
    final newWeekStart = WeekHelper.getWeekStart(date);
    state = state.copyWith(
      weekStartDate: newWeekStart,
      selectedDay: newWeekStart, // Reset to Saturday
    );
    await loadAttendanceData();
  }

  /// Select a day in the week
  void selectDay(DateTime day) {
    state = state.copyWith(selectedDay: day);
  }

  /// Load attendance data for the selected class and week
  Future<void> loadAttendanceData() async {
    if (state.selectedClass == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final studentsWithAttendance = await _getWeeklyAttendanceUseCase.getWithStudents(
        classId: state.selectedClass!.id,
        weekStartDate: state.weekStartDate,
      );

      final studentInputs = studentsWithAttendance.map((swa) {
        return StudentAttendanceInput(
          student: swa.student,
          dailyStatus: swa.weeklyAttendance.dailyAttendance,
          hasChanges: false,
        );
      }).toList();

      state = state.copyWith(
        students: studentInputs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set attendance status for a student on the selected day
  void setAttendanceStatus(String studentId, AttendanceStatus status) {
    final normalizedDay = DateTime(
      state.selectedDay.year,
      state.selectedDay.month,
      state.selectedDay.day,
    );

    final updatedStudents = state.students.map((s) {
      if (s.student.id == studentId) {
        final newDailyStatus = Map<DateTime, AttendanceStatus>.from(s.dailyStatus);
        newDailyStatus[normalizedDay] = status;
        return s.copyWith(dailyStatus: newDailyStatus, hasChanges: true);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  /// Mark all students with a status for the selected day
  void markAllForDay(AttendanceStatus status) {
    final normalizedDay = DateTime(
      state.selectedDay.year,
      state.selectedDay.month,
      state.selectedDay.day,
    );

    final updatedStudents = state.students.map((s) {
      final newDailyStatus = Map<DateTime, AttendanceStatus>.from(s.dailyStatus);
      newDailyStatus[normalizedDay] = status;
      return s.copyWith(dailyStatus: newDailyStatus, hasChanges: true);
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Save all attendance changes
  Future<bool> saveAttendance() async {
    if (state.selectedClass == null) return false;

    state = state.copyWith(isSaving: true, error: null, clearMessages: true);

    try {
      // Build the map of student -> (date -> status)
      final Map<String, Map<DateTime, AttendanceStatus>> studentDayStatuses = {};

      for (final studentInput in state.students) {
        if (studentInput.hasChanges) {
          studentDayStatuses[studentInput.student.id] = studentInput.dailyStatus;
        }
      }

      if (studentDayStatuses.isNotEmpty) {
        await _saveAttendanceUseCase.saveForWeek(
          classId: state.selectedClass!.id,
          studentDayStatuses: studentDayStatuses,
        );
      }

      // Reset hasChanges for all students
      final updatedStudents = state.students.map((s) {
        return s.copyWith(hasChanges: false);
      }).toList();

      state = state.copyWith(
        students: updatedStudents,
        isSaving: false,
        successMessage: 'تم حفظ الحضور بنجاح',
      );

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  /// Go to previous week
  Future<void> previousWeek() async {
    final newWeekStart = state.weekStartDate.subtract(const Duration(days: 7));
    await changeWeek(newWeekStart);
  }

  /// Go to next week
  Future<void> nextWeek() async {
    final newWeekStart = state.weekStartDate.add(const Duration(days: 7));
    await changeWeek(newWeekStart);
  }
}

/// Provider for attendance entry controller
final attendanceEntryControllerProvider = StateNotifierProvider.autoDispose
    .family<AttendanceEntryController, AttendanceEntryState, String?>((
  ref,
  classId,
) {
  final controller = getIt<AttendanceEntryController>();
  controller.initialize(classId: classId);
  return controller;
});
