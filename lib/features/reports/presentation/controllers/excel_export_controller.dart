import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_classes_usecase.dart';
import 'package:moalem/features/reports/domain/entities/excel_export_entity.dart';
import 'package:moalem/features/reports/domain/usecases/export_yearly_work_usecase.dart';

/// Controller for Excel export functionality
@injectable
class ExcelExportController extends StateNotifier<ExcelExportState> {
  final ExportYearlyWorkUseCase _exportYearlyWorkUseCase;
  final GetClassesUseCase _getClassesUseCase;

  ExcelExportController(this._exportYearlyWorkUseCase, this._getClassesUseCase)
    : super(const ExcelExportState());

  /// Load available classes
  Future<void> loadClasses() async {
    state = state.copyWith(isLoadingClasses: true, errorMessage: null);

    try {
      final classes = await _getClassesUseCase();
      state = state.copyWith(
        isLoadingClasses: false,
        classes: classes,
        selectedClass: classes.isNotEmpty ? classes.first : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingClasses: false,
        errorMessage: 'Failed to load classes: $e',
      );
    }
  }

  /// Select educational stage
  void selectStage(EducationalStage stage) {
    state = state.copyWith(selectedStage: stage);

    // Filter classes by stage
    final filtered = state.classes
        .where((c) => _mapEvaluationGroupToStage(c.evaluationGroup) == stage)
        .toList();

    if (filtered.isNotEmpty) {
      selectClass(filtered.first);
    }
  }

  /// Select class
  void selectClass(ClassEntity classEntity) {
    state = state.copyWith(selectedClass: classEntity);
  }

  /// Select export type
  void selectExportType(ExportType type) {
    state = state.copyWith(exportType: type);
  }

  /// Toggle semester average inclusion
  void toggleIncludeSemesterAverage(bool value) {
    state = state.copyWith(includeSemesterAverage: value);
  }

  /// Toggle monthly exams inclusion
  void toggleIncludeMonthlyExams(bool value) {
    state = state.copyWith(includeMonthlyExams: value);
  }

  /// Set governorate
  void setGovernorate(String governorate) {
    state = state.copyWith(governorate: governorate);
  }

  /// Set administration
  void setAdministration(String administration) {
    state = state.copyWith(administration: administration);
  }

  /// Export to Excel
  Future<void> exportToExcel({
    required List<StudentYearlyWorkData> studentsData,
  }) async {
    if (state.selectedClass == null) {
      state = state.copyWith(errorMessage: 'Please select a class');
      return;
    }

    if (state.governorate.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter governorate');
      return;
    }

    if (state.administration.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter administration');
      return;
    }

    state = state.copyWith(isExporting: true, errorMessage: null);

    final params = ExportYearlyWorkParams(
      classEntity: state.selectedClass!,
      governorate: state.governorate,
      administration: state.administration,
      studentsData: studentsData,
      includeSemesterAverage: state.includeSemesterAverage,
      includeMonthlyExams: state.includeMonthlyExams,
    );

    final result = await _exportYearlyWorkUseCase(params: params);

    result.fold(
      (failure) => state = state.copyWith(
        isExporting: false,
        errorMessage: failure.message,
      ),
      (filePath) => state = state.copyWith(
        isExporting: false,
        exportedFilePath: filePath,
        successMessage: 'تم تصدير Excel بنجاح',
      ),
    );
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear error message
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  /// Map EvaluationGroup to EducationalStage
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

/// State for Excel export controller
class ExcelExportState {
  final bool isLoadingClasses;
  final bool isExporting;
  final List<ClassEntity> classes;
  final EducationalStage? selectedStage;
  final ClassEntity? selectedClass;
  final ExportType exportType;
  final bool includeSemesterAverage;
  final bool includeMonthlyExams;
  final String governorate;
  final String administration;
  final String? exportedFilePath;
  final String? successMessage;
  final String? errorMessage;

  const ExcelExportState({
    this.isLoadingClasses = false,
    this.isExporting = false,
    this.classes = const [],
    this.selectedStage,
    this.selectedClass,
    this.exportType = ExportType.yearlyWork,
    this.includeSemesterAverage = true,
    this.includeMonthlyExams = true,
    this.governorate = '',
    this.administration = '',
    this.exportedFilePath,
    this.successMessage,
    this.errorMessage,
  });

  ExcelExportState copyWith({
    bool? isLoadingClasses,
    bool? isExporting,
    List<ClassEntity>? classes,
    EducationalStage? selectedStage,
    ClassEntity? selectedClass,
    ExportType? exportType,
    bool? includeSemesterAverage,
    bool? includeMonthlyExams,
    String? governorate,
    String? administration,
    String? exportedFilePath,
    String? successMessage,
    String? errorMessage,
  }) {
    return ExcelExportState(
      isLoadingClasses: isLoadingClasses ?? this.isLoadingClasses,
      isExporting: isExporting ?? this.isExporting,
      classes: classes ?? this.classes,
      selectedStage: selectedStage ?? this.selectedStage,
      selectedClass: selectedClass ?? this.selectedClass,
      exportType: exportType ?? this.exportType,
      includeSemesterAverage:
          includeSemesterAverage ?? this.includeSemesterAverage,
      includeMonthlyExams: includeMonthlyExams ?? this.includeMonthlyExams,
      governorate: governorate ?? this.governorate,
      administration: administration ?? this.administration,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for ExcelExportController
final excelExportControllerProvider =
    StateNotifierProvider<ExcelExportController, ExcelExportState>((ref) {
      return getIt<ExcelExportController>();
    });
