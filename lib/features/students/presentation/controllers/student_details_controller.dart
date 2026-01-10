import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/students/domain/entities/student_details_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';
import 'package:moalem/features/students/domain/usecases/get_student_details_with_scores_usecase.dart';
import 'package:moalem/features/students/domain/usecases/update_student_score_usecase.dart';
import 'package:uuid/uuid.dart';

/// State class for student details with filter state
class StudentDetailsState {
  final AsyncValue<StudentDetailsWithScores?> data;
  final PeriodType periodType;
  final int periodNumber;
  final bool isSaving;
  final Map<String, int> pendingScoreChanges; // evaluationId -> score
  final AttendanceStatus? pendingAttendanceStatus;
  final String? pendingNotes;

  const StudentDetailsState({
    required this.data,
    this.periodType = PeriodType.weekly,
    this.periodNumber = 1,
    this.isSaving = false,
    this.pendingScoreChanges = const {},
    this.pendingAttendanceStatus,
    this.pendingNotes,
  });

  StudentDetailsState copyWith({
    AsyncValue<StudentDetailsWithScores?>? data,
    PeriodType? periodType,
    int? periodNumber,
    bool? isSaving,
    Map<String, int>? pendingScoreChanges,
    AttendanceStatus? pendingAttendanceStatus,
    String? pendingNotes,
  }) {
    return StudentDetailsState(
      data: data ?? this.data,
      periodType: periodType ?? this.periodType,
      periodNumber: periodNumber ?? this.periodNumber,
      isSaving: isSaving ?? this.isSaving,
      pendingScoreChanges: pendingScoreChanges ?? this.pendingScoreChanges,
      pendingAttendanceStatus:
          pendingAttendanceStatus ?? this.pendingAttendanceStatus,
      pendingNotes: pendingNotes ?? this.pendingNotes,
    );
  }

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges =>
      pendingScoreChanges.isNotEmpty ||
      pendingAttendanceStatus != null ||
      pendingNotes != null;
}

final studentDetailsControllerProvider =
    StateNotifierProvider.family<
      StudentDetailsController,
      StudentDetailsState,
      String
    >((ref, studentId) {
      return StudentDetailsController(
        getIt<GetStudentDetailsWithScoresUseCase>(),
        getIt<UpdateStudentScoreUseCase>(),
        studentId,
      );
    });

class StudentDetailsController extends StateNotifier<StudentDetailsState> {
  final GetStudentDetailsWithScoresUseCase _getStudentDetailsUseCase;
  final UpdateStudentScoreUseCase _updateScoreUseCase;
  final String _studentId;

  StudentDetailsController(
    this._getStudentDetailsUseCase,
    this._updateScoreUseCase,
    this._studentId,
  ) : super(const StudentDetailsState(data: AsyncValue.loading())) {
    loadStudentDetails();
  }

  /// Load student details with current period filters
  Future<void> loadStudentDetails() async {
    state = state.copyWith(
      data: const AsyncValue.loading(),
      pendingScoreChanges: {},
      pendingAttendanceStatus: null,
      pendingNotes: null,
    );
    try {
      final details = await _getStudentDetailsUseCase(
        _studentId,
        state.periodType,
        state.periodNumber,
      );
      state = state.copyWith(data: AsyncValue.data(details));
    } catch (e, stack) {
      state = state.copyWith(data: AsyncValue.error(e, stack));
    }
  }

  /// Change period type and reload data
  Future<void> changePeriodType(PeriodType type) async {
    if (state.periodType == type) return;
    state = state.copyWith(periodType: type);
    await loadStudentDetails();
  }

  /// Change period number and reload data
  Future<void> changePeriodNumber(int number) async {
    if (state.periodNumber == number) return;
    state = state.copyWith(periodNumber: number);
    await loadStudentDetails();
  }

  /// Update a score locally (pending save)
  void updateScore(String evaluationId, int newScore) {
    final newChanges = Map<String, int>.from(state.pendingScoreChanges);
    newChanges[evaluationId] = newScore;
    state = state.copyWith(pendingScoreChanges: newChanges);
  }

  /// Increment score for an evaluation
  void incrementScore(String evaluationId, int maxScore) {
    final currentScore = _getCurrentScore(evaluationId);
    if (currentScore < maxScore) {
      updateScore(evaluationId, currentScore + 1);
    }
  }

  /// Decrement score for an evaluation
  void decrementScore(String evaluationId) {
    final currentScore = _getCurrentScore(evaluationId);
    if (currentScore > 0) {
      updateScore(evaluationId, currentScore - 1);
    }
  }

  /// Get current score (pending or saved)
  int _getCurrentScore(String evaluationId) {
    if (state.pendingScoreChanges.containsKey(evaluationId)) {
      return state.pendingScoreChanges[evaluationId]!;
    }
    return state.data.value?.getScoreForEvaluation(evaluationId) ?? 0;
  }

  /// Get display score for UI (considers pending changes)
  int getDisplayScore(String evaluationId) {
    return _getCurrentScore(evaluationId);
  }

  /// Update attendance status locally (pending save)
  void updateAttendanceStatus(AttendanceStatus status) {
    state = state.copyWith(pendingAttendanceStatus: status);
  }

  /// Update notes locally (pending save)
  void updateNotes(String notes) {
    state = state.copyWith(pendingNotes: notes);
  }

  /// Save all pending changes
  Future<bool> saveChanges() async {
    final details = state.data.value;
    if (details == null) return false;

    state = state.copyWith(isSaving: true);

    try {
      // Save each pending score change
      for (final entry in state.pendingScoreChanges.entries) {
        final evaluationId = entry.key;
        final score = entry.value;

        final existingScore = details.scores[evaluationId];
        final scoreEntity = StudentScoreEntity(
          id: existingScore?.id ?? const Uuid().v4(),
          studentId: _studentId,
          evaluationId: evaluationId,
          score: score,
          periodType: state.periodType,
          periodNumber: state.periodNumber,
          attendanceStatus:
              state.pendingAttendanceStatus ?? existingScore?.attendanceStatus,
          notes: state.pendingNotes ?? existingScore?.notes,
          createdAt: existingScore?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _updateScoreUseCase(scoreEntity);
      }

      // If only attendance or notes changed without score changes
      if (state.pendingScoreChanges.isEmpty &&
          (state.pendingAttendanceStatus != null ||
              state.pendingNotes != null)) {
        // Find the attendance evaluation and update it
        final attendanceEval = details.evaluations.firstWhere(
          (e) => e.name == 'attendance_and_diligence',
          orElse: () => details.evaluations.first,
        );

        final existingScore = details.scores[attendanceEval.id];
        final scoreEntity = StudentScoreEntity(
          id: existingScore?.id ?? const Uuid().v4(),
          studentId: _studentId,
          evaluationId: attendanceEval.id,
          score: existingScore?.score ?? 0,
          periodType: state.periodType,
          periodNumber: state.periodNumber,
          attendanceStatus:
              state.pendingAttendanceStatus ?? existingScore?.attendanceStatus,
          notes: state.pendingNotes ?? existingScore?.notes,
          createdAt: existingScore?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _updateScoreUseCase(scoreEntity);
      }

      state = state.copyWith(isSaving: false);

      // Reload to get fresh data
      await loadStudentDetails();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  /// Calculate total score including pending changes
  int get totalScore {
    final details = state.data.value;
    if (details == null) return 0;

    int total = 0;
    for (final evaluation in details.evaluations) {
      total += getDisplayScore(evaluation.id);
    }
    return total;
  }

  /// Calculate percentage including pending changes
  double get percentage {
    final details = state.data.value;
    if (details == null || details.maxPossibleScore == 0) return 0;
    return (totalScore / details.maxPossibleScore) * 100;
  }
}
