import 'dart:io';
import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
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
    String titleText;
    if (printData.isMultiWeek) {
      titleText = printData.printType == PrintType.scores
          ? 'سجل رصد درجات فصل'
          : 'سجل الحضور والغياب';
    } else {
      titleText =
          'تقرير ${printData.printType == PrintType.scores ? 'الدرجات' : 'الحضور'}';
    }
    titleCell.setText(titleText);
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
    // Period info - show week dates for attendance or multi-week range
    if (printData.isMultiWeek) {
      final weekNums = printData.weekNumbers;
      currentRow = _addMetadataRow(
        sheet,
        currentRow,
        'الفترة',
        'الأسابيع ${weekNums.first} - ${weekNums.last}',
      );
    } else if (printData.printType == PrintType.attendance &&
        printData.weekStartDate != null) {
      final dateFormat = DateFormat('d/M/yyyy', 'ar');
      currentRow = _addMetadataRow(
        sheet,
        currentRow,
        'الأسبوع',
        '${dateFormat.format(printData.weekStartDate!)} - ${dateFormat.format(printData.weekEndDate!)}',
      );
    } else {
      currentRow = _addMetadataRow(
        sheet,
        currentRow,
        'الفترة',
        'الأسبوع ${printData.periodNumber}',
      );
    }
    currentRow += 1;

    // Yield to UI thread
    await Future.delayed(Duration.zero);

    // Create table headers (multi-week has two header rows)
    if (printData.isMultiWeek) {
      currentRow = _createMultiWeekHeaders(sheet, currentRow, printData);
      currentRow += 1;
    } else {
      currentRow = _createTableHeaders(sheet, currentRow, printData);
      currentRow += 1;
    }

    // Yield to UI thread
    await Future.delayed(Duration.zero);

    // Add student data
    if (printData.isMultiWeek) {
      await _addMultiWeekStudentData(sheet, currentRow, printData);
    } else {
      await _addStudentData(sheet, currentRow, printData);
    }

    // Auto-fit columns (more columns for multi-week)
    final maxCols = printData.isMultiWeek ? 50 : 20;
    for (var col = 1; col <= maxCols; col++) {
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
      // Weekly attendance with day columns (Sat-Thu)
      if (printData.weekStartDate != null) {
        final weekDays = printData.weekDays;
        final dateFormat = DateFormat('d/M', 'ar');

        for (final day in weekDays) {
          cell = sheet.getRangeByIndex(row, col);
          final dayName = WeekHelper.getShortDayNameArabic(day.weekday);
          cell.setText('$dayName\n${dateFormat.format(day)}');
          _styleHeaderCell(cell);
          col++;
        }
      } else {
        // Legacy single status header
        cell = sheet.getRangeByIndex(row, col);
        cell.setText('الحالة');
        _styleHeaderCell(cell);
      }
    }

    return row;
  }

  void _styleHeaderCell(xlsio.Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#4472C4';
    cell.cellStyle.fontColor = '#FFFFFF';
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
  }

  /// Create multi-week headers with two rows:
  /// Row 1: Week group headers (merged across evaluation/day columns)
  /// Row 2: Evaluation or day sub-headers for each week
  int _createMultiWeekHeaders(
    xlsio.Worksheet sheet,
    int row,
    PrintDataEntity printData,
  ) {
    final weekNumbers = printData.weekNumbers;
    final dateFormat = DateFormat('d/M', 'ar');

    // Determine columns per week based on print type
    int colsPerWeek;
    if (printData.printType == PrintType.scores &&
        printData.evaluations != null) {
      colsPerWeek = printData.evaluations!.length + 1; // evaluations + total
    } else if (printData.printType == PrintType.attendance) {
      colsPerWeek = 6; // Sat, Sun, Mon, Tue, Wed, Thu (6 days)
    } else {
      return row;
    }

    // Row 1: Student number, name, then week group headers
    int col = 1;

    // Student number header (spans 2 rows)
    var cell = sheet.getRangeByIndex(row, col);
    cell.setText('م');
    _styleHeaderCell(cell);
    sheet.getRangeByIndex(row, col, row + 1, col).merge();
    col++;

    // Student name header (spans 2 rows)
    cell = sheet.getRangeByIndex(row, col);
    cell.setText('الاسم');
    _styleHeaderCell(cell);
    sheet.getRangeByIndex(row, col, row + 1, col).merge();
    col++;

    // Week group headers (row 1)
    for (final weekNum in weekNumbers) {
      final startCol = col;
      final endCol = col + colsPerWeek - 1;

      // Merged week header
      cell = sheet.getRangeByIndex(row, startCol);
      final weekStartDate = printData.weekStartDates?[weekNum];
      String weekLabel = 'الأسبوع ${_getArabicOrdinal(weekNum)}';
      if (weekStartDate != null) {
        weekLabel += ' ${dateFormat.format(weekStartDate)}';
      }
      cell.setText(weekLabel);
      _styleWeekHeaderCell(cell);
      sheet.getRangeByIndex(row, startCol, row, endCol).merge();

      col = endCol + 1;
    }

    // Row 2: Sub-headers for each week
    col = 3; // Start after م and الاسم

    if (printData.printType == PrintType.scores &&
        printData.evaluations != null) {
      // Evaluation sub-headers
      for (final _ in weekNumbers) {
        for (final evaluation in printData.evaluations!) {
          cell = sheet.getRangeByIndex(row + 1, col);
          cell.setText(_getEvaluationShortName(evaluation.name));
          _styleSubHeaderCell(cell);
          col++;
        }

        // Total header
        cell = sheet.getRangeByIndex(row + 1, col);
        cell.setText('المجموع');
        _styleTotalHeaderCell(cell);
        col++;
      }
    } else if (printData.printType == PrintType.attendance) {
      // Day sub-headers (Sat to Thu)
      final dayNames = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس'];
      for (final weekNum in weekNumbers) {
        final weekStartDate = printData.weekStartDates?[weekNum];
        final weekDays = weekStartDate != null
            ? WeekHelper.getWeekDays(weekStartDate)
            : <DateTime>[];

        for (var i = 0; i < 6; i++) {
          cell = sheet.getRangeByIndex(row + 1, col);
          if (weekDays.isNotEmpty && i < weekDays.length) {
            cell.setText('${dayNames[i]}\n${dateFormat.format(weekDays[i])}');
          } else {
            cell.setText(dayNames[i]);
          }
          _styleSubHeaderCell(cell);
          col++;
        }
      }
    }

    return row + 1; // Return the row after the second header row
  }

  void _styleWeekHeaderCell(xlsio.Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#305496'; // Darker blue
    cell.cellStyle.fontColor = '#FFFFFF';
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
  }

  void _styleSubHeaderCell(xlsio.Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#BDD7EE'; // Light blue
    cell.cellStyle.fontColor = '#000000';
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
  }

  void _styleTotalHeaderCell(xlsio.Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#FFE699'; // Light yellow
    cell.cellStyle.fontColor = '#000000';
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
  }

  String _getArabicOrdinal(int number) {
    const ordinals = {
      1: 'الأول',
      2: 'الثاني',
      3: 'الثالث',
      4: 'الرابع',
      5: 'الخامس',
      6: 'السادس',
      7: 'السابع',
      8: 'الثامن',
      9: 'التاسع',
      10: 'العاشر',
      11: 'الحادي عشر',
      12: 'الثاني عشر',
      13: 'الثالث عشر',
      14: 'الرابع عشر',
      15: 'الخامس عشر',
    };
    return ordinals[number] ?? '$number';
  }

  /// Add multi-week student data
  Future<void> _addMultiWeekStudentData(
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

        _addMultiWeekStudentRow(sheet, rowIndex, studentData, printData);
      }

      // Yield to UI thread after each batch
      await Future.delayed(Duration.zero);
    }
  }

  void _addMultiWeekStudentRow(
    xlsio.Worksheet sheet,
    int rowIndex,
    StudentPrintData studentData,
    PrintDataEntity printData,
  ) {
    final weekNumbers = printData.weekNumbers;
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
      // Scores for each week
      final evaluations = printData.evaluations!;
      for (final weekNum in weekNumbers) {
        // Evaluation scores
        for (final evaluation in evaluations) {
          final score = studentData.getScoreForWeek(weekNum, evaluation.id);
          cell = sheet.getRangeByIndex(rowIndex, col);
          cell.setNumber(score.toDouble());
          cell.cellStyle.hAlign = xlsio.HAlignType.center;
          col++;
        }

        // Week total
        final weekTotal = studentData.getTotalForWeek(weekNum);
        cell = sheet.getRangeByIndex(rowIndex, col);
        cell.setNumber(weekTotal.toDouble());
        cell.cellStyle.hAlign = xlsio.HAlignType.center;
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor =
            '#FFF2CC'; // Light yellow background for totals
        col++;
      }
    } else if (printData.printType == PrintType.attendance) {
      // Attendance for each week (6 days per week)
      for (final weekNum in weekNumbers) {
        final weekStartDate = printData.weekStartDates?[weekNum];
        final weekDays = weekStartDate != null
            ? WeekHelper.getWeekDays(weekStartDate)
            : <DateTime>[];

        for (var i = 0; i < 6; i++) {
          cell = sheet.getRangeByIndex(rowIndex, col);
          if (weekDays.isNotEmpty && i < weekDays.length) {
            final day = weekDays[i];
            final status = studentData.getAttendanceForWeekDate(weekNum, day);
            if (status != null) {
              cell.setText(_getAttendanceStatusSymbol(status));
              _styleAttendanceCell(cell, status);
            } else {
              cell.setText('-');
              cell.cellStyle.hAlign = xlsio.HAlignType.center;
            }
          } else {
            cell.setText('-');
            cell.cellStyle.hAlign = xlsio.HAlignType.center;
          }
          col++;
        }
      }
    }
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
      // Weekly attendance with day columns (Sat-Thu)
      if (printData.weekStartDate != null &&
          studentData.attendanceDaily != null) {
        final weekDays = printData.weekDays;

        for (final day in weekDays) {
          cell = sheet.getRangeByIndex(rowIndex, col);
          final status = studentData.getAttendanceForDate(day);
          if (status != null) {
            cell.setText(_getAttendanceStatusSymbol(status));
            _styleAttendanceCell(cell, status);
          } else {
            cell.setText('-');
            cell.cellStyle.hAlign = xlsio.HAlignType.center;
          }
          col++;
        }
      } else {
        // Legacy single status
        final attendanceData = studentData.attendance ?? {};
        final status = attendanceData.values.isNotEmpty
            ? _getAttendanceStatusText(attendanceData.values.first)
            : '-';

        cell = sheet.getRangeByIndex(rowIndex, col);
        cell.setText(status);
        cell.cellStyle.hAlign = xlsio.HAlignType.right;
      }
    }
  }

  /// Style attendance cell based on status
  void _styleAttendanceCell(xlsio.Range cell, AttendanceStatus status) {
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    switch (status) {
      case AttendanceStatus.present:
        cell.cellStyle.backColor = '#C6EFCE'; // Light green
        cell.cellStyle.fontColor = '#006100'; // Dark green
        break;
      case AttendanceStatus.absent:
        cell.cellStyle.backColor = '#FFC7CE'; // Light red
        cell.cellStyle.fontColor = '#9C0006'; // Dark red
        break;
      case AttendanceStatus.excused:
        cell.cellStyle.backColor = '#FFEB9C'; // Light yellow
        cell.cellStyle.fontColor = '#9C5700'; // Dark yellow
        break;
    }
  }

  /// Get short symbol for attendance status
  String _getAttendanceStatusSymbol(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '✓';
      case AttendanceStatus.absent:
        return '✗';
      case AttendanceStatus.excused:
        return 'إ';
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
