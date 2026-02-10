import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_values.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_class_by_id_usecase.dart';
import 'package:moalem/features/classes/domain/usecases/get_evaluations_usecase.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_input_entity.dart';
import 'package:moalem/features/students/domain/usecases/get_student_by_qr_code_usecase.dart';
import 'package:moalem/features/students/domain/usecases/get_students_by_class_id_usecase.dart';
import 'package:moalem/features/students/domain/usecases/update_student_score_usecase.dart';
import 'package:uuid/uuid.dart';

class BulkScoreEntryState {
  final ClassEntity? classInfo;
  final List<EvaluationEntity> availableEvaluations;
  final EvaluationEntity? selectedEvaluation;
  final PeriodType periodType;
  final int periodNumber;
  final List<StudentScoreInput> students;
  final Map<String, StudentScoreEntity> existingScores;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final int bulkScore;

  BulkScoreEntryState({
    this.classInfo,
    this.availableEvaluations = const [],
    this.selectedEvaluation,
    this.periodType = PeriodType.weekly,
    this.periodNumber = 1,
    this.students = const [],
    this.existingScores = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.bulkScore = 0,
  });

  BulkScoreEntryState copyWith({
    ClassEntity? classInfo,
    List<EvaluationEntity>? availableEvaluations,
    EvaluationEntity? selectedEvaluation,
    PeriodType? periodType,
    int? periodNumber,
    List<StudentScoreInput>? students,
    Map<String, StudentScoreEntity>? existingScores,
    String? searchQuery,
    bool? isLoading,
    String? error,
    int? bulkScore,
  }) {
    return BulkScoreEntryState(
      classInfo: classInfo ?? this.classInfo,
      availableEvaluations: availableEvaluations ?? this.availableEvaluations,
      selectedEvaluation: selectedEvaluation ?? this.selectedEvaluation,
      periodType: periodType ?? this.periodType,
      periodNumber: periodNumber ?? this.periodNumber,
      students: students ?? this.students,
      existingScores: existingScores ?? this.existingScores,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bulkScore: bulkScore ?? this.bulkScore,
    );
  }

  List<StudentScoreInput> get filteredStudents {
    if (searchQuery.isEmpty) return students;
    return students
        .where(
          (s) =>
              s.student.name.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<StudentScoreInput> get selectedStudents {
    return students.where((s) => s.isSelected).toList();
  }

  bool get allSelected {
    return students.isNotEmpty && students.every((s) => s.isSelected);
  }

  int get selectedCount => selectedStudents.length;

  int? get currentMaxScore => selectedEvaluation?.maxScore;
}

@injectable
class BulkScoreEntryController extends StateNotifier<BulkScoreEntryState> {
  final GetClassByIdUseCase _getClassByIdUseCase;
  final GetEvaluationsUseCase _getEvaluationsUseCase;
  final GetStudentsByClassIdUseCase _getStudentsByClassIdUseCase;
  final UpdateStudentScoreUseCase _updateStudentScoreUseCase;
  final GetStudentByQrCodeUseCase _getStudentByQrCodeUseCase;

  List<EvaluationEntity> _allEvaluations = [];

  BulkScoreEntryController(
    this._getClassByIdUseCase,
    this._getEvaluationsUseCase,
    this._getStudentsByClassIdUseCase,
    this._updateStudentScoreUseCase,
    this._getStudentByQrCodeUseCase,
  ) : super(BulkScoreEntryState());

  Future<void> loadClassData(String classId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get class info
      final classInfo = await _getClassByIdUseCase(classId);
      if (classInfo == null) {
        state = state.copyWith(isLoading: false, error: 'Class not found');
        return;
      }

      // Set initial state including class info
      // For High school, default to Monthly
      // For others, default to Weekly (from initial state)
      var periodType = state.periodType;
      var periodNumber = state.periodNumber;

      if (classInfo.evaluationGroup == EvaluationGroup.high) {
        periodType = PeriodType.monthly;
        periodNumber = 1; // Start at Feb (index 1) which is default for High
      }

      // Get all evaluations and store them
      _allEvaluations = await _getEvaluationsUseCase();

      // Get students
      final students = await _getStudentsByClassIdUseCase(classId);
      final studentInputs = students
          .map((s) => StudentScoreInput(student: s, currentScore: 0))
          .toList();

      state = state.copyWith(
        classInfo: classInfo,
        students: studentInputs,
        periodType: periodType,
        periodNumber: periodNumber,
      );

      _updateAvailableEvaluations();

      state = state.copyWith(isLoading: false);

      // Load existing scores for the first evaluation
      if (state.selectedEvaluation != null) {
        await _loadExistingScores();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _updateAvailableEvaluations() {
    if (state.classInfo == null) return;

    final evaluationScoresMap = _getEvaluationScoresMap(
      state.classInfo!.evaluationGroup,
    );

    final List<EvaluationEntity> filtered = _allEvaluations
        .where((e) => evaluationScoresMap.containsKey(e.name))
        .map(
          (e) =>
              e.copyWith(maxScore: evaluationScoresMap[e.name] ?? e.maxScore),
        )
        .where((e) {
          final isPrimaryOrPrep =
              state.classInfo!.evaluationGroup == EvaluationGroup.primary ||
              state.classInfo!.evaluationGroup == EvaluationGroup.secondary;
          final isHighSchool =
              state.classInfo!.evaluationGroup == EvaluationGroup.high;

          // Logic for Primary/Secondary
          if (isPrimaryOrPrep) {
            if (state.periodType == PeriodType.monthly) {
              // In Monthly view, STRICTLY show only the relevant exam
              if (state.periodNumber == 2) {
                // March
                return e.name == 'first_month_exam';
              } else if (state.periodNumber == 3) {
                // April
                return e.name == 'second_month_exam';
              } else {
                return false; // No monthly value to show for other months
              }
            } else {
              // In Weekly view, STRICTLY hide monthly exams
              if (e.name == 'first_month_exam' ||
                  e.name == 'second_month_exam' ||
                  e.name == 'months_exam_average') {
                return false;
              }
              return true;
            }
          }

          // Logic for High School (Default Monthly)
          if (isHighSchool) {
            if (state.periodType == PeriodType.monthly) {
              if (e.name == 'first_month_exam') {
                return state.periodNumber == 2; // Month 2 (March)
              }
              if (e.name == 'second_month_exam') {
                return state.periodNumber == 3; // Month 3 (April)
              }
            } else {
              // If weekly (shouldn't happen for High School usually but safe guard)
              if (e.name == 'first_month_exam' ||
                  e.name == 'second_month_exam') {
                return false;
              }
            }
          }
          return true;
        })
        .toList();

    state = state.copyWith(
      availableEvaluations: filtered,
      selectedEvaluation: filtered.contains(state.selectedEvaluation)
          ? state.selectedEvaluation
          : (filtered.isNotEmpty ? filtered.first : null),
    );
  }

  Map<String, int> _getEvaluationScoresMap(EvaluationGroup evaluationGroup) {
    switch (evaluationGroup) {
      case EvaluationGroup.prePrimary:
        return EvaluationValues.prePrimaryEvaluationScores;
      case EvaluationGroup.primary:
        return EvaluationValues.primaryEvaluationScores;
      case EvaluationGroup.secondary:
        return EvaluationValues.secondaryEvaluationScores;
      case EvaluationGroup.high:
        return EvaluationValues.highSchoolEvaluationScores;
    }
  }

  Future<void> _loadExistingScores() async {
    if (state.selectedEvaluation == null) return;

    // For now, we'll start with empty scores
    // In a production app, you'd want to query the database for existing scores
    // based on the selected evaluation, period type, and period number
    final updatedStudents = state.students.map((s) {
      return s.copyWith(currentScore: 0, isSelected: false);
    }).toList();

    state = state.copyWith(students: updatedStudents, bulkScore: 0);
  }

  void selectEvaluation(EvaluationEntity evaluation) {
    state = state.copyWith(selectedEvaluation: evaluation, bulkScore: 0);
    _loadExistingScores();
  }

  void changePeriodType(PeriodType type) {
    int newPeriodNumber = 1;
    if (type == PeriodType.monthly) {
      // Default to March (2) if switching to monthly as it's common
      if (state.periodNumber < 2 || state.periodNumber > 3) {
        newPeriodNumber = 2;
      } else {
        newPeriodNumber = state.periodNumber;
      }
    } else {
      newPeriodNumber = state.periodNumber > 18 ? 1 : state.periodNumber;
    }

    state = state.copyWith(periodType: type, periodNumber: newPeriodNumber);
    _updateAvailableEvaluations();
    _loadExistingScores();
  }

  void changePeriodNumber(int number) {
    state = state.copyWith(periodNumber: number);
    _updateAvailableEvaluations();
    _loadExistingScores();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleStudentSelection(String studentId) {
    final updatedStudents = state.students.map((s) {
      if (s.student.id == studentId) {
        return s.copyWith(isSelected: !s.isSelected);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  void toggleSelectAll() {
    final newSelectionState = !state.allSelected;
    final updatedStudents = state.students.map((s) {
      return s.copyWith(isSelected: newSelectionState);
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  void incrementScore(String studentId) {
    final maxScore = state.currentMaxScore ?? 0;
    final updatedStudents = state.students.map((s) {
      if (s.student.id == studentId && s.currentScore < maxScore) {
        return s.copyWith(currentScore: s.currentScore + 1);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  void decrementScore(String studentId) {
    final updatedStudents = state.students.map((s) {
      if (s.student.id == studentId && s.currentScore > 0) {
        return s.copyWith(currentScore: s.currentScore - 1);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  void setScore(String studentId, int score) {
    final maxScore = state.currentMaxScore ?? 0;
    final clampedScore = score.clamp(0, maxScore);

    final updatedStudents = state.students.map((s) {
      if (s.student.id == studentId) {
        return s.copyWith(currentScore: clampedScore);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  void incrementSelectedScores() {
    final maxScore = state.currentMaxScore ?? 0;
    final newBulkScore = (state.bulkScore + 1).clamp(0, maxScore);

    final updatedStudents = state.students.map((s) {
      if (s.isSelected && s.currentScore < maxScore) {
        return s.copyWith(
          currentScore: (s.currentScore + 1).clamp(0, maxScore),
        );
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents, bulkScore: newBulkScore);
  }

  void decrementSelectedScores() {
    final newBulkScore = (state.bulkScore - 1).clamp(
      0,
      state.currentMaxScore ?? 0,
    );

    final updatedStudents = state.students.map((s) {
      if (s.isSelected && s.currentScore > 0) {
        return s.copyWith(currentScore: s.currentScore - 1);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents, bulkScore: newBulkScore);
  }

  void setMaxScoreForSelected() {
    final maxScore = state.currentMaxScore ?? 0;
    final updatedStudents = state.students.map((s) {
      if (s.isSelected) {
        return s.copyWith(currentScore: maxScore);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents, bulkScore: maxScore);
  }

  Future<void> saveSelectedScores() async {
    if (state.selectedEvaluation == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final studentsToSave = state.selectedCount > 0
          ? state.selectedStudents
          : state.students;
      const uuid = Uuid();

      for (final studentInput in studentsToSave) {
        final scoreEntity = StudentScoreEntity(
          id: uuid.v4(),
          studentId: studentInput.student.id,
          evaluationId: state.selectedEvaluation!.id,
          score: studentInput.currentScore,
          periodType: state.periodType,
          periodNumber: state.periodNumber,
          createdAt: DateTime.now(),
        );

        await _updateStudentScoreUseCase(scoreEntity);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<StudentEntity?> handleQrScanned(String qrCode) async {
    try {
      final student = await _getStudentByQrCodeUseCase(qrCode);
      if (student != null && student.classId == state.classInfo?.id) {
        return student;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<StudentEntity>> handleMultipleQrScanned(
    List<String> qrCodes,
  ) async {
    final List<StudentEntity> foundStudents = [];
    for (final code in qrCodes) {
      try {
        final student = await _getStudentByQrCodeUseCase(code);
        if (student != null && student.classId == state.classInfo?.id) {
          foundStudents.add(student);
        }
      } catch (_) {
        // Skip invalid/not found
      }
    }
    return foundStudents;
  }

  Future<void> updateMultipleStudentsScores(
    List<String> studentIds,
    int score,
  ) async {
    if (state.selectedEvaluation == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      for (final studentId in studentIds) {
        final scoreEntity = StudentScoreEntity(
          id: const Uuid().v4(),
          studentId: studentId,
          evaluationId: state.selectedEvaluation!.id,
          score: score,
          periodType: state.periodType,
          periodNumber: state.periodNumber,
          createdAt: DateTime.now(),
        );

        await _updateStudentScoreUseCase(scoreEntity);
      }

      // Update local state to reflect the change
      final updatedStudents = state.students.map((s) {
        if (studentIds.contains(s.student.id)) {
          return s.copyWith(currentScore: score);
        }
        return s;
      }).toList();

      state = state.copyWith(students: updatedStudents, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStudentScore(String studentId, int score) async {
    if (state.selectedEvaluation == null) return;

    try {
      final scoreEntity = StudentScoreEntity(
        id: const Uuid().v4(),
        studentId: studentId,
        evaluationId: state.selectedEvaluation!.id,
        score: score,
        periodType: state.periodType,
        periodNumber: state.periodNumber,
        createdAt: DateTime.now(),
      );

      await _updateStudentScoreUseCase(scoreEntity);

      // Update local state to reflect the change
      final updatedStudents = state.students.map((s) {
        if (s.student.id == studentId) {
          return s.copyWith(currentScore: score);
        }
        return s;
      }).toList();

      state = state.copyWith(students: updatedStudents);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final bulkScoreEntryControllerProvider = StateNotifierProvider.autoDispose
    .family<BulkScoreEntryController, BulkScoreEntryState, String>((
      ref,
      classId,
    ) {
      final controller = getIt<BulkScoreEntryController>();
      controller.loadClassData(classId);
      return controller;
    });
