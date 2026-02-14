import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:moalem/core/constants/app_enums.dart' hide AttendanceStatus;
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/reports/data/strategies/export_strategies.dart';
import 'package:moalem/features/reports/domain/entities/excel_export_entity.dart'
    as excel_ent;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

@injectable
class ExcelExportService {
  Future<String> exportToExcel(PrintDataEntity data) async {
    return _export(data, false);
  }

  Future<String> exportEmptyAttendanceSheet(PrintDataEntity data) async {
    return _export(data, true);
  }

  Future<String> _export(PrintDataEntity data, bool isEmpty) async {
    final excelEntity = _mapToExcelEntity(data, isEmpty);
    final strategy = _getStrategy(excelEntity);
    final workbook = await strategy.prepareWorkbook();

    // Set RTL
    if (workbook.worksheets.count > 0) {
      workbook.worksheets[0].isRightToLeft = true;
    }

    await strategy.execute(workbook, excelEntity);

    return await _saveAndShare(workbook, data);
  }

  TemplateStrategy _getStrategy(excel_ent.ExcelExportEntity data) {
    // Determine strategy based on stage/type
    // Using mapping from PrintDataEntity logic which we preserved in Entity conversion

    if (data.exportType == excel_ent.ExportType.attendance) {
      return AttendanceExportStrategy();
    }

    switch (data.stage) {
      case excel_ent.EducationalStage.prePrimary:
        return PrePrimaryExportStrategy();
      case excel_ent.EducationalStage.primary:
        return PrimaryExportStrategy();
      case excel_ent.EducationalStage.preparatory:
        return PreparatoryExportStrategy();
      case excel_ent.EducationalStage.secondary:
        return SecondaryExportStrategy();
    }
  }

  excel_ent.ExcelExportEntity _mapToExcelEntity(
    PrintDataEntity data, [
    bool isEmpty = false,
  ]) {
    // Map PrintDataEntity to ExcelExportEntity

    excel_ent.EducationalStage stage;
    switch (data.classEntity.evaluationGroup) {
      case EvaluationGroup.prePrimary:
        stage = excel_ent.EducationalStage.prePrimary;
        break;
      case EvaluationGroup.primary:
        stage = excel_ent.EducationalStage.primary;
        break;
      case EvaluationGroup.secondary:
        stage = excel_ent.EducationalStage.preparatory; // Note mapping
        break;
      case EvaluationGroup.high:
        stage = excel_ent.EducationalStage.secondary; // Note mapping
        break;
    }

    excel_ent.ExportType type = excel_ent.ExportType.scores;
    if (data.printType == PrintType.attendance) {
      type = excel_ent.ExportType.attendance;
    }

    final students = data.studentsData
        .map(
          (s) => excel_ent.StudentExportData(
            studentId: s.student.id,
            name: s.student.name,
            number: s.student.number,
            weeklyScores: s.weeklyScores ?? {},
            weeklyTotals: s.weeklyTotals ?? {},
            monthlyExamScores: s.monthlyExamScores,
            weeklyAttendance: isEmpty
                ? null
                : s.weeklyAttendance?.map(
                    (k, v) => MapEntry(
                      k,
                      v.map((d, status) {
                        excel_ent.AttendanceStatus mappedStatus;
                        switch (status.name) {
                          case 'present':
                            mappedStatus = excel_ent.AttendanceStatus.present;
                            break;
                          case 'absent':
                            mappedStatus = excel_ent.AttendanceStatus.absent;
                            break;
                          case 'excused':
                            mappedStatus = excel_ent.AttendanceStatus.excused;
                            break;
                          default:
                            mappedStatus = excel_ent.AttendanceStatus.present;
                        }
                        return MapEntry(d, mappedStatus);
                      }),
                    ),
                  ),
          ),
        )
        .toList();

    return excel_ent.ExcelExportEntity(
      id: 'generated_${DateTime.now().millisecondsSinceEpoch}',
      exportType: type,
      stage: stage,
      schoolInfo: excel_ent.SchoolInfo(
        governorate: data.governorate,
        administration: data.administration,
        schoolName: data.classEntity.school,
      ),
      classInfo: excel_ent.ClassInfo(
        className: data.classEntity.name,
        grade: data.classEntity.grade,
        subject: data.classEntity.subject,
      ),
      students: students,
      options: excel_ent.ExportOptions(exportDate: DateTime.now()),
      createdAt: DateTime.now(),
      weekStartDates: data.weekStartDates,
    );
  }

  Future<String> _saveAndShare(Workbook workbook, PrintDataEntity data) async {
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    String safe(String v) => v.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    final fileName =
        '${safe(data.classEntity.name)}_'
        '${data.classEntity.evaluationGroup.name}_$ts.xlsx';

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(path)]);
    return path;
  }
}
