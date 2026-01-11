import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_values.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_class_by_id_usecase.dart';
import 'package:moalem/features/classes/domain/usecases/get_evaluations_usecase.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_input_entity.dart';
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

  BulkScoreEntryController(
    this._getClassByIdUseCase,
    this._getEvaluationsUseCase,
    this._getStudentsByClassIdUseCase,
    this._updateStudentScoreUseCase,
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

      // Get all evaluations
      final allEvaluations = await _getEvaluationsUseCase();

      // Filter evaluations by class group and override max scores
      final evaluationScoresMap = _getEvaluationScoresMap(
        classInfo.evaluationGroup,
      );
      final availableEvaluations = allEvaluations
          .where((e) => evaluationScoresMap.containsKey(e.name))
          .map(
            (e) =>
                e.copyWith(maxScore: evaluationScoresMap[e.name] ?? e.maxScore),
          )
          .toList();

      // Get students
      final students = await _getStudentsByClassIdUseCase(classId);
      final studentInputs = students
          .map((s) => StudentScoreInput(student: s, currentScore: 0))
          .toList();

      state = state.copyWith(
        classInfo: classInfo,
        availableEvaluations: availableEvaluations,
        selectedEvaluation: availableEvaluations.isNotEmpty
            ? availableEvaluations.first
            : null,
        students: studentInputs,
        isLoading: false,
      );

      // Load existing scores for the first evaluation
      if (state.selectedEvaluation != null) {
        await _loadExistingScores();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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

    state = state.copyWith(students: updatedStudents);
  }

  void selectEvaluation(EvaluationEntity evaluation) {
    state = state.copyWith(selectedEvaluation: evaluation);
    _loadExistingScores();
  }

  void changePeriodType(PeriodType type) {
    state = state.copyWith(periodType: type, periodNumber: 1);
    _loadExistingScores();
  }

  void changePeriodNumber(int number) {
    state = state.copyWith(periodNumber: number);
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

  void setMaxScoreForSelected() {
    final maxScore = state.currentMaxScore ?? 0;
    final updatedStudents = state.students.map((s) {
      if (s.isSelected) {
        return s.copyWith(currentScore: maxScore);
      }
      return s;
    }).toList();

    state = state.copyWith(students: updatedStudents);
  }

  Future<void> saveSelectedScores() async {
    if (state.selectedEvaluation == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final selectedStudents = state.selectedStudents;
      const uuid = Uuid();

      for (final studentInput in selectedStudents) {
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
