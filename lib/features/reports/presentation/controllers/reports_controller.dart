import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/extensions/evaluation_group_extensions.dart'; // Added
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_classes_usecase.dart';
import 'package:moalem/features/reports/domain/usecases/get_class_report_usecase.dart';

/// State for the reports screen
class ReportsState {
  final AsyncValue<List<ClassEntity>> classes;
  final String? selectedStage;
  final String? selectedClassId;
  final AsyncValue<ClassReportData?> reportData;
  final PeriodType periodType;
  final int periodNumber;
  final Set<String> selectedStudentIds;
  final bool selectAll;

  const ReportsState({
    this.classes = const AsyncValue.loading(),
    this.selectedStage,
    this.selectedClassId,
    this.reportData = const AsyncValue.loading(),
    this.periodType = PeriodType.weekly,
    this.periodNumber = 1,
    this.selectedStudentIds = const {},
    this.selectAll = false,
  });

  ReportsState copyWith({
    AsyncValue<List<ClassEntity>>? classes,
    String? selectedStage,
    String? selectedClassId,
    AsyncValue<ClassReportData?>? reportData,
    PeriodType? periodType,
    int? periodNumber,
    Set<String>? selectedStudentIds,
    bool? selectAll,
  }) {
    return ReportsState(
      classes: classes ?? this.classes,
      selectedStage: selectedStage ?? this.selectedStage,
      selectedClassId: selectedClassId ?? this.selectedClassId,
      reportData: reportData ?? this.reportData,
      periodType: periodType ?? this.periodType,
      periodNumber: periodNumber ?? this.periodNumber,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      selectAll: selectAll ?? this.selectAll,
    );
  }

  bool isStudentSelected(String studentId) {
    return selectedStudentIds.contains(studentId);
  }

  int get selectedCount => selectedStudentIds.length;
}

final reportsControllerProvider =
    StateNotifierProvider<ReportsController, ReportsState>((ref) {
      return ReportsController(
        getIt<GetClassesUseCase>(),
        getIt<GetClassReportUseCase>(),
      );
    });

class ReportsController extends StateNotifier<ReportsState> {
  final GetClassesUseCase _getClassesUseCase;
  final GetClassReportUseCase _getClassReportUseCase;

  ReportsController(this._getClassesUseCase, this._getClassReportUseCase)
    : super(const ReportsState()) {
    loadClasses();
  }

  /// Load all classes
  Future<void> loadClasses() async {
    state = state.copyWith(classes: const AsyncValue.loading());
    try {
      final classes = await _getClassesUseCase();
      final firstClass = classes.isNotEmpty ? classes.first : null;
      state = state.copyWith(
        classes: AsyncValue.data(classes),
        selectedStage: null,
        selectedClassId: firstClass?.id,
      );

      // Auto-load report for first class
      if (classes.isNotEmpty) {
        await loadReport();
      }
    } catch (e, stack) {
      state = state.copyWith(classes: AsyncValue.error(e, stack));
    }
  }

  /// Select a stage and filter classes
  Future<void> selectStage(String? stage) async {
    if (state.selectedStage == stage) return;

    final allClasses = state.classes.value ?? [];
    final filteredClasses = allClasses
        .where((c) => stage == null || c.evaluationGroup.stageName == stage)
        .toList();

    state = state.copyWith(
      selectedStage: stage,
      selectedClassId: filteredClasses.isNotEmpty
          ? filteredClasses.first.id
          : null,
      selectedStudentIds: {},
      selectAll: false,
    );

    await loadReport();
  }

  /// Select a class
  Future<void> selectClass(String classId) async {
    if (state.selectedClassId == classId) return;
    state = state.copyWith(
      selectedClassId: classId,
      selectedStudentIds: {},
      selectAll: false,
    );
    await loadReport();
  }

  /// Change period number
  Future<void> changePeriodNumber(int number) async {
    if (state.periodNumber == number) return;
    state = state.copyWith(
      periodNumber: number,
      selectedStudentIds: {},
      selectAll: false,
    );
    await loadReport();
  }

  /// Load report data
  Future<void> loadReport() async {
    final classId = state.selectedClassId;
    if (classId == null) return;

    state = state.copyWith(reportData: const AsyncValue.loading());
    try {
      final reportData = await _getClassReportUseCase(
        classId,
        state.periodType,
        state.periodNumber,
      );
      state = state.copyWith(reportData: AsyncValue.data(reportData));
    } catch (e, stack) {
      state = state.copyWith(reportData: AsyncValue.error(e, stack));
    }
  }

  /// Toggle student selection
  void toggleStudentSelection(String studentId) {
    final selected = Set<String>.from(state.selectedStudentIds);
    if (selected.contains(studentId)) {
      selected.remove(studentId);
    } else {
      selected.add(studentId);
    }

    final reportData = state.reportData.value;
    final allSelected =
        reportData != null &&
        selected.length == reportData.studentReports.length;

    state = state.copyWith(
      selectedStudentIds: selected,
      selectAll: allSelected,
    );
  }

  /// Toggle select all
  void toggleSelectAll() {
    final reportData = state.reportData.value;
    if (reportData == null) return;

    if (state.selectAll) {
      // Deselect all
      state = state.copyWith(selectedStudentIds: {}, selectAll: false);
    } else {
      // Select all
      final allIds = reportData.studentReports.map((s) => s.student.id).toSet();
      state = state.copyWith(selectedStudentIds: allIds, selectAll: true);
    }
  }

  /// Export selected students to Excel
  Future<void> exportToExcel() async {}

  /// Export selected students to PDF
  Future<void> exportToPdf() async {}
}
