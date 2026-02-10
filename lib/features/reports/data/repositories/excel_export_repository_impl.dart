import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:moalem/features/reports/data/strategies/template_strategy_manager.dart';
import 'package:moalem/features/reports/domain/entities/excel_export_entity.dart';
import 'package:moalem/features/reports/domain/repositories/excel_export_repository.dart';
import 'package:moalem/features/reports/domain/usecases/export_yearly_work_usecase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Implementation of ExcelExportRepository using the excel package
/// Supports template loading and preserves styling
@Injectable(as: ExcelExportRepository)
class ExcelExportRepositoryImpl implements ExcelExportRepository {
  final TemplateStrategyManager _strategyManager;

  ExcelExportRepositoryImpl(this._strategyManager);

  @override
  Future<String> exportScores({required ExcelExportEntity exportData}) async {
    try {
      final bytes = await _strategyManager.exportExcel(exportData);
      final fileName = _generateFileName(exportData);
      return await _saveAndShare(Uint8List.fromList(bytes), fileName);
    } catch (e) {
      throw ExcelExportException('Failed to export scores: $e');
    }
  }

  @override
  Future<String> exportAttendance({
    required ExcelExportEntity exportData,
  }) async {
    throw UnimplementedError('Attendance export not yet implemented');
  }

  @override
  Future<String> exportYearlyWork({
    required ExcelExportEntity exportData,
  }) async {
    try {
      final bytes = await _strategyManager.exportExcel(exportData);
      final fileName = _generateFileName(exportData);
      return await _saveAndShare(Uint8List.fromList(bytes), fileName);
    } catch (e) {
      throw ExcelExportException('Failed to export yearly work: $e');
    }
  }

  @override
  List<TemplateInfo> getAvailableTemplates(EducationalStage stage) {
    return _strategyManager.getTemplatesForStage(stage);
  }

  @override
  Future<ExportPreview> previewExport({
    required ExcelExportEntity exportData,
  }) async {
    final missingData = <String>[];

    if (exportData.schoolInfo.governorate.isEmpty) {
      missingData.add('Governorate');
    }
    if (exportData.schoolInfo.administration.isEmpty) {
      missingData.add('Administration');
    }
    if (exportData.schoolInfo.schoolName.isEmpty) {
      missingData.add('School name');
    }
    if (exportData.classInfo.className.isEmpty) {
      missingData.add('Class name');
    }
    if (exportData.classInfo.subject.isEmpty) {
      missingData.add('Subject');
    }
    if (exportData.students.isEmpty) {
      missingData.add('Students');
    }

    return ExportPreview(
      studentCount: exportData.students.length,
      weekCount: 18,
      missingData: missingData,
      isValid: missingData.isEmpty,
    );
  }

  /// Generate file name for export
  String _generateFileName(ExcelExportEntity exportData) {
    final timestamp = DateTime.now();
    final dateStr =
        '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';

    String typePrefix;
    switch (exportData.exportType) {
      case ExportType.scores:
        typePrefix = 'scores';
        break;
      case ExportType.attendance:
        typePrefix = 'attendance';
        break;
      case ExportType.yearlyWork:
        typePrefix = 'yearly_work';
        break;
    }

    return '${typePrefix}_${exportData.classInfo.className}_${exportData.classInfo.subject}_$dateStr$timeStr.xlsx';
  }

  /// Save bytes to file and share
  Future<String> _saveAndShare(Uint8List bytes, String fileName) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share file
      await Share.shareXFiles([XFile(filePath)], subject: fileName);

      return filePath;
    } catch (e) {
      throw ExcelExportException('Failed to save and share file: $e');
    }
  }
}
