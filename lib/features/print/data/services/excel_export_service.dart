import 'dart:io';
import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// Service to export print data to Excel
/// Creates Excel files from scratch (Syncfusion xlsio can only create, not read)
@injectable
class ExcelExportService {
  ExcelExportService();

  /// Export print data to Excel file
  Future<String> exportToExcel(PrintDataEntity printData) async {
    try {
      // Create a new workbook
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'التقرير';

      // Enable RTL for the sheet
      sheet.isRightToLeft = true;

      // Build the Excel structure
      await _buildExcelStructure(sheet, printData);

      // Yield to UI thread
      await Future.delayed(Duration.zero);

      // Save the file
      final filePath = await _saveAndShareExcelFile(
        workbook.saveAsStream(),
        printData,
      );

      // Dispose workbook
      workbook.dispose();

      return filePath;
    } catch (e) {
      throw Exception('Failed to export Excel: $e');
    }
  }

  /// Build the entire Excel structure
  Future<void> _buildExcelStructure(
    xlsio.Worksheet sheet,
    PrintDataEntity printData,
  ) async {
    int currentRow = 1;

    // Create title
    final titleCell = sheet.getRangeByIndex(currentRow, 1);
    titleCell.setText(
      'تقرير ${printData.printType == PrintType.scores ? 'الدرجات' : 'الحضور'}',
    );
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontSize = 16;
    titleCell.cellStyle.hAlign = xlsio.HAlignType.right;
    sheet.getRangeByIndex(currentRow, 1, currentRow, 6).merge();
    currentRow += 2;

    // Create metadata section
    currentRow = _addMetadataRow(
      sheet,
      currentRow,
      'المحافظة',
      printData.governorate,
    );
    currentRow = _addMetadataRow(
      sheet,
      currentRow,
      'الإدارة التعليمية',
      printData.administration,
    );
    currentRow = _addMetadataRow(
      sheet,
      currentRow,
      'المدرسة',
      printData.classEntity.school,
    );
    currentRow = _addMetadataRow(
      sheet,
      currentRow,
      'الفصل',
      printData.classEntity.name,
    );
    currentRow = _addMetadataRow(
      sheet,
      currentRow,
      'المادة',
      printData.classEntity.subject,
    );
    currentRow = _addMetadataRow(
      sheet,
      currentRow,
      'الفترة',
      'الأسبوع ${printData.periodNumber}',
    );
    currentRow += 1;

    // Yield to UI thread
    await Future.delayed(Duration.zero);

    // Create table headers
    currentRow = _createTableHeaders(sheet, currentRow, printData);
    currentRow += 1;

    // Yield to UI thread
    await Future.delayed(Duration.zero);

    // Add student data
    await _addStudentData(sheet, currentRow, printData);

    // Auto-fit columns
    for (var col = 1; col <= 20; col++) {
      sheet.autoFitColumn(col);
    }
  }

  int _addMetadataRow(
    xlsio.Worksheet sheet,
    int row,
    String label,
    String value,
  ) {
    final labelCell = sheet.getRangeByIndex(row, 1);
    labelCell.setText(label);
    labelCell.cellStyle.bold = true;
    labelCell.cellStyle.hAlign = xlsio.HAlignType.right;

    final valueCell = sheet.getRangeByIndex(row, 2);
    valueCell.setText(value);
    valueCell.cellStyle.hAlign = xlsio.HAlignType.right;

    return row + 1;
  }

  int _createTableHeaders(
    xlsio.Worksheet sheet,
    int row,
    PrintDataEntity printData,
  ) {
    int col = 1;

    // Student number header
    var cell = sheet.getRangeByIndex(row, col);
    cell.setText('رقم الطالب');
    _styleHeaderCell(cell);
    col++;

    // Student name header
    cell = sheet.getRangeByIndex(row, col);
    cell.setText('اسم الطالب');
    _styleHeaderCell(cell);
    col++;

    if (printData.printType == PrintType.scores &&
        printData.evaluations != null) {
      // Evaluation headers
      for (final evaluation in printData.evaluations!) {
        cell = sheet.getRangeByIndex(row, col);
        cell.setText(_getEvaluationShortName(evaluation.name));
        _styleHeaderCell(cell);
        col++;
      }

      // Total header
      cell = sheet.getRangeByIndex(row, col);
      cell.setText('المجموع');
      _styleHeaderCell(cell);
    } else if (printData.printType == PrintType.attendance) {
      // Attendance status header
      cell = sheet.getRangeByIndex(row, col);
      cell.setText('الحالة');
      _styleHeaderCell(cell);
    }

    return row;
  }

  void _styleHeaderCell(xlsio.Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#4472C4';
    cell.cellStyle.fontColor = '#FFFFFF';
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
  }

  Future<void> _addStudentData(
    xlsio.Worksheet sheet,
    int startRow,
    PrintDataEntity printData,
  ) async {
    const batchSize = 10;

    for (var i = 0; i < printData.studentsData.length; i += batchSize) {
      final end = (i + batchSize < printData.studentsData.length)
          ? i + batchSize
          : printData.studentsData.length;

      for (var j = i; j < end; j++) {
        final studentData = printData.studentsData[j];
        final rowIndex = startRow + j;

        _addStudentRow(sheet, rowIndex, studentData, printData);
      }

      // Yield to UI thread after each batch
      await Future.delayed(Duration.zero);
    }
  }

  void _addStudentRow(
    xlsio.Worksheet sheet,
    int rowIndex,
    StudentPrintData studentData,
    PrintDataEntity printData,
  ) {
    int col = 1;

    // Student number
    var cell = sheet.getRangeByIndex(rowIndex, col);
    cell.setNumber(
      (int.tryParse(studentData.student.number.toString()) ?? 0).toDouble(),
    );
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    col++;

    // Student name
    cell = sheet.getRangeByIndex(rowIndex, col);
    cell.setText(studentData.student.name);
    cell.cellStyle.hAlign = xlsio.HAlignType.right;
    col++;

    if (printData.printType == PrintType.scores &&
        printData.evaluations != null) {
      // Scores for each evaluation
      for (final evaluation in printData.evaluations!) {
        final score = studentData.scores[evaluation.id] ?? 0;
        cell = sheet.getRangeByIndex(rowIndex, col);
        cell.setNumber(score.toDouble());
        cell.cellStyle.hAlign = xlsio.HAlignType.center;

        col++;
      }

      // Total score
      cell = sheet.getRangeByIndex(rowIndex, col);
      cell.setNumber(studentData.totalScore.toDouble());
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.bold = true;
    } else if (printData.printType == PrintType.attendance) {
      // Attendance status
      final attendanceData = studentData.attendance ?? {};
      final status = attendanceData.values.isNotEmpty
          ? _getAttendanceStatusText(attendanceData.values.first)
          : '-';

      cell = sheet.getRangeByIndex(rowIndex, col);
      cell.setText(status);
      cell.cellStyle.hAlign = xlsio.HAlignType.right;
    }
  }

  String _getAttendanceStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.excused:
        return 'إذن';
    }
  }

  String _getEvaluationShortName(String name) {
    final Map<String, String> shortNames = {
      'classroom_performance': 'الأداء الصفي',
      'homework_book': 'الواجب',
      'activity_book': 'النشاط',
      'weekly_review': 'التقييم',
      'oral_tasks': 'الشفهي',
      'skill_tasks': 'المهارية',
      'skills_performance': 'الأدائية',
      'months_exam_average': 'الامتحانات',
      'attendance_and_diligence': 'الحضور',
      'first_month_exam': 'الشهر الأول',
      'second_month_exam': 'الشهر الثاني',
    };

    return shortNames[name] ?? name;
  }

  Future<String> _saveAndShareExcelFile(
    List<int> fileBytes,
    PrintDataEntity printData,
  ) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final typePrefix = printData.printType == PrintType.scores
          ? 'scores'
          : 'attendance';
      final className = printData.classEntity.name.replaceAll('/', '_');
      final filename = '${typePrefix}_${className}_$timestamp.xlsx';

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: filename,
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );

      return filePath;
    } catch (e) {
      throw Exception('Failed to save Excel file: $e');
    }
  }
}
