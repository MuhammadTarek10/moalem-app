import 'package:moalem/features/reports/domain/entities/excel_export_entity.dart';

/// Repository interface for Excel export operations
abstract class ExcelExportRepository {
  /// Export student scores to Excel using template-based approach
  /// Returns the file path of the exported file
  Future<String> exportScores({required ExcelExportEntity exportData});

  /// Export attendance records to Excel
  Future<String> exportAttendance({required ExcelExportEntity exportData});

  /// Export yearly work report (أعمال السنة)
  Future<String> exportYearlyWork({required ExcelExportEntity exportData});

  /// Get available templates for a stage
  List<TemplateInfo> getAvailableTemplates(EducationalStage stage);

  /// Preview export data (for validation)
  Future<ExportPreview> previewExport({required ExcelExportEntity exportData});
}

/// Template information
class TemplateInfo {
  final String name;
  final String assetPath;
  final EducationalStage stage;
  final ExportType type;

  const TemplateInfo({
    required this.name,
    required this.assetPath,
    required this.stage,
    required this.type,
  });
}

/// Export preview for validation
class ExportPreview {
  final int studentCount;
  final int weekCount;
  final List<String> missingData;
  final bool isValid;

  const ExportPreview({
    required this.studentCount,
    required this.weekCount,
    required this.missingData,
    required this.isValid,
  });
}
