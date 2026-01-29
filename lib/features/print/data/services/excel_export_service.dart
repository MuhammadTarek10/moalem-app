import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:moalem/core/constants/app_enums.dart' hide AttendanceStatus;
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
      if (printData.printType == PrintType.scores &&
          printData.classEntity.evaluationGroup == EvaluationGroup.prePrimary) {
        return await _exportFromPrePrimaryTemplate(printData);
      }

      if (printData.printType == PrintType.scores &&
          printData.classEntity.evaluationGroup == EvaluationGroup.primary) {
        return await _exportFromPrimaryTemplate(printData);
      }

      if (printData.printType == PrintType.scores &&
          printData.classEntity.evaluationGroup == EvaluationGroup.secondary) {
        return await _exportFromSecondaryTemplate(printData);
      }

      if (printData.printType == PrintType.attendance) {
        await _buildStyledAttendanceStructure(sheet, printData);
      } else {
        await _buildExcelStructure(sheet, printData);
      }

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
        return '√';
      case AttendanceStatus.absent:
        return 'غ';
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

  /// Export preprimary scores by creating Excel from scratch with proper styling
  /// Since the excel package doesn't preserve template styling, we recreate
  /// the exact template structure programmatically using syncfusion_flutter_xlsio
  Future<String> _exportFromPrePrimaryTemplate(
    PrintDataEntity printData,
  ) async {
    // =========================================================================
    // CREATE NEW WORKBOOK WITH TEMPLATE STYLING
    // =========================================================================
    // Since the excel package doesn't preserve styling when loading templates,
    // we create the file from scratch using syncfusion_flutter_xlsio which has
    // better styling support.
    // =========================================================================

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'كشف الدرجات';
    sheet.isRightToLeft = false;

    // Configuration constants
    // Configuration constants
    const int weekBlockSize = 8; // 1 total + 7 evaluations per week
    const int firstWeekStartCol = 3; // Column C (1-indexed = 3)
    const int serialNumberCol = 1; // Column A
    const int studentNameCol = 2; // Column B

    // Evaluation IDs in reversed order (RTL layout)
    // Col 0=أداء صفي, Col 1=واجب, Col 2=نشاط, Col 3=تقييم أسبوعي, Col 4=شفهية, Col 5=مهارية, Col 6=حضور, Col 7=المجموع
    final evalIds = [
      'classroom_performance',
      'homework_book',
      'activity_book',
      'weekly_review',
      'oral_tasks',
      'skill_tasks',
      'attendance_and_diligence',
    ];

    final subNames = [
      'كراس أداء صفي',
      'كراس الواجب',
      'كراس النشاط',
      'تقييم أسبوعي',
    ];

    final otherNames = ['مهام شفهية', 'مهام مهارية', 'حضور و مواظبة'];

    // Max scores matching the order above: 20, 20, 20, 20, 10, 5, 5
    final maxScores = [20, 20, 20, 20, 10, 5, 5];

    final weekNumbers = printData.weekNumbers;
    final dateFormat = DateFormat('yyyy\\M\\d'); // Matches template format

    // =========================================================================
    // DEFINE STYLES
    // =========================================================================

    // Base header style
    final baseHeaderStyle = workbook.styles.add('BaseHeaderStyle');
    baseHeaderStyle.bold = true;
    baseHeaderStyle.fontSize = 12;
    baseHeaderStyle.hAlign = xlsio.HAlignType.center;
    baseHeaderStyle.vAlign = xlsio.VAlignType.center;
    baseHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    baseHeaderStyle.borders.all.color = '#000000';

    // Week header style - White background
    final weekHeaderStyle = workbook.styles.add('WeekHeaderStyle');
    weekHeaderStyle.backColor = '#FFFFFF';
    weekHeaderStyle.bold = true;
    weekHeaderStyle.fontSize = 14;
    weekHeaderStyle.hAlign = xlsio.HAlignType.center;
    weekHeaderStyle.vAlign = xlsio.VAlignType.center;
    weekHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    weekHeaderStyle.borders.all.color = '#000000';

    // Column Styles (Alternating Gray/White)
    final grayStyle = workbook.styles.add('GrayStyle');
    grayStyle.backColor = '#D9D9D9';
    grayStyle.hAlign = xlsio.HAlignType.center;
    grayStyle.vAlign = xlsio.VAlignType.center;
    grayStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    grayStyle.borders.all.color = '#000000';
    grayStyle.fontSize = 14;
    grayStyle.bold = true;

    final whiteStyle = workbook.styles.add('WhiteStyle');
    whiteStyle.backColor = '#FFFFFF';
    whiteStyle.hAlign = xlsio.HAlignType.center;
    whiteStyle.vAlign = xlsio.VAlignType.center;
    whiteStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    whiteStyle.borders.all.color = '#000000';
    whiteStyle.fontSize = 14;
    whiteStyle.bold = true;

    // Vertical Text Headers
    final verticalGrayHeader = workbook.styles.add('VerticalGrayHeader');
    verticalGrayHeader.backColor = '#D9D9D9';
    verticalGrayHeader.hAlign = xlsio.HAlignType.center;
    verticalGrayHeader.vAlign = xlsio.VAlignType.center;
    verticalGrayHeader.borders.all.lineStyle = xlsio.LineStyle.thin;
    verticalGrayHeader.borders.all.color = '#000000';
    verticalGrayHeader.rotation =
        180; // Top to down in xlsio (91-180 is clockwise)
    verticalGrayHeader.bold = true;
    verticalGrayHeader.fontSize = 16;

    final verticalWhiteHeader = workbook.styles.add('VerticalWhiteHeader');
    verticalWhiteHeader.backColor = '#FFFFFF';
    verticalWhiteHeader.hAlign = xlsio.HAlignType.center;
    verticalWhiteHeader.vAlign = xlsio.VAlignType.center;
    verticalWhiteHeader.borders.all.lineStyle = xlsio.LineStyle.thin;
    verticalWhiteHeader.borders.all.color = '#000000';
    verticalWhiteHeader.rotation = 180; // Top to down in xlsio
    verticalWhiteHeader.bold = true;
    verticalWhiteHeader.fontSize = 16;

    // Student name style
    final studentNameStyle = workbook.styles.add('StudentNameStyle');
    studentNameStyle.hAlign = xlsio.HAlignType.right;
    studentNameStyle.vAlign = xlsio.VAlignType.center;
    studentNameStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    studentNameStyle.borders.all.color = '#000000';
    studentNameStyle.fontSize = 15;
    studentNameStyle.bold = true;

    // Data cell alternating styles (for scores)
    final grayDataStyle = workbook.styles.add('GrayDataStyle');
    grayDataStyle.backColor = '#D9D9D9';
    grayDataStyle.hAlign = xlsio.HAlignType.center;
    grayDataStyle.vAlign = xlsio.VAlignType.center;
    grayDataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    grayDataStyle.borders.all.color = '#000000';
    grayDataStyle.fontSize = 14;
    grayDataStyle.bold = true;

    final whiteDataStyle = workbook.styles.add('WhiteDataStyle');
    whiteDataStyle.backColor = '#FFFFFF';
    whiteDataStyle.hAlign = xlsio.HAlignType.center;
    whiteDataStyle.vAlign = xlsio.VAlignType.center;
    whiteDataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    whiteDataStyle.borders.all.color = '#000000';
    whiteDataStyle.fontSize = 14;
    whiteDataStyle.bold = true;

    // =========================================================================
    // HEADER SECTION
    // =========================================================================
    int currentRow = 1;
    final int lastTableCol =
        firstWeekStartCol + (weekNumbers.length * weekBlockSize) - 1;
    xlsio.Range cell;

    // 1. Logo Position (Far Top Right)
    try {
      final ByteData logoData = await rootBundle.load(
        'assets/images/minist_logo.png',
      );
      final List<int> bytes = logoData.buffer.asUint8List();
      final int logoCol = (lastTableCol > 10) ? lastTableCol - 1 : 10;
      final xlsio.Picture picture = sheet.pictures.addStream(
        currentRow,
        logoCol,
        bytes,
      );
      picture.height = 85;
      picture.width = 85;
    } catch (e) {
      // ignore logo if error
    }

    // 2. Left Metadata (Rows 1-3)
    void setLeftHeaderCell(int row, String text) {
      final c = sheet.getRangeByIndex(row, 1, row, 10);
      c.merge();
      c.setText(text);
      c.cellStyle.fontSize = 14;
      c.cellStyle.hAlign = xlsio.HAlignType.center;
      c.cellStyle.bold = true;
      // Also increase row height for metadata
      sheet.getRangeByIndex(row, 1).rowHeight = 30;
    }

    setLeftHeaderCell(
      currentRow++,
      'مديرية التربية والتعليم ${printData.governorate}',
    );
    setLeftHeaderCell(currentRow++, 'إدارة ${printData.administration}');
    setLeftHeaderCell(currentRow++, 'مدرسة ${printData.classEntity.school}');

    // 3. Row 4: Title and Subject (Centered together with extra space)
    final rowRange = sheet.getRangeByIndex(
      currentRow,
      1,
      currentRow,
      lastTableCol,
    );
    rowRange.merge();
    rowRange.setText(
      'سجل رصد درجات فصل  ${printData.classEntity.grade}                                               مادة : ${printData.classEntity.subject}',
    );
    rowRange.cellStyle.bold = true;
    rowRange.cellStyle.fontSize = 18;
    rowRange.cellStyle.hAlign = xlsio.HAlignType.center;
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 40;

    currentRow += 2;

    // =========================================================================
    // TABLE HEADERS
    // =========================================================================
    int headerRow = currentRow;

    // م and الاسم (spans rows for all header logic)
    cell = sheet.getRangeByIndex(headerRow, serialNumberCol);
    cell.setText('م');
    cell.cellStyle = baseHeaderStyle;
    cell.cellStyle.backColor = '#D9D9D9';
    sheet
        .getRangeByIndex(
          headerRow,
          serialNumberCol,
          headerRow + 3,
          serialNumberCol,
        )
        .merge();

    cell = sheet.getRangeByIndex(headerRow, studentNameCol);
    cell.setText('الاسم');
    cell.cellStyle = baseHeaderStyle;
    sheet
        .getRangeByIndex(
          headerRow,
          studentNameCol,
          headerRow + 3,
          studentNameCol,
        )
        .merge();

    // Week headers
    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekNum = weekNumbers[weekIdx];
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);
      final weekEndCol = weekStartCol + weekBlockSize - 1;

      String weekLabel = 'الأسبوع ${_getArabicOrdinal(weekNum)}';
      // Manual override as requested: Start from 7/2/2026
      final DateTime baseStartDate = DateTime(2026, 2, 7);
      final DateTime weekStartDate = baseStartDate.add(
        Duration(days: weekIdx * 7),
      );

      weekLabel += ' ${dateFormat.format(weekStartDate)}';

      cell = sheet.getRangeByIndex(headerRow, weekStartCol);
      cell.setText(weekLabel);
      cell.cellStyle = weekHeaderStyle;
      sheet
          .getRangeByIndex(headerRow, weekStartCol, headerRow, weekEndCol)
          .merge();

      // Row 2 of header block: جوانب التقييم merged over index 0-3
      cell = sheet.getRangeByIndex(headerRow + 1, weekStartCol);
      cell.setText('جوانب التقييم');
      cell.cellStyle = whiteStyle;
      sheet
          .getRangeByIndex(
            headerRow + 1,
            weekStartCol,
            headerRow + 1,
            weekStartCol + 3,
          )
          .merge();

      // Row 3 of header block: Sub-headers for G-J (0-3)
      for (var sIdx = 0; sIdx < 4; sIdx++) {
        cell = sheet.getRangeByIndex(headerRow + 2, weekStartCol + sIdx);
        cell.setText(subNames[sIdx]);
        // Alternating colors: اداء (White), واجب (Gray), نشاط (White), تقييم (Gray)
        cell.cellStyle = (sIdx % 2 == 0)
            ? verticalWhiteHeader
            : verticalGrayHeader;
      }

      // Column 4-6: Other evaluations ( شففهية, مهارية, حضور)
      for (var oIdx = 0; oIdx < 3; oIdx++) {
        cell = sheet.getRangeByIndex(headerRow + 1, weekStartCol + 4 + oIdx);
        cell.setText(otherNames[oIdx]);
        cell.cellStyle = (oIdx % 2 == 0)
            ? verticalWhiteHeader
            : verticalGrayHeader;
        sheet
            .getRangeByIndex(
              headerRow + 1,
              weekStartCol + 4 + oIdx,
              headerRow + 2,
              weekStartCol + 4 + oIdx,
            )
            .merge();
      }

      // Column 7: المجموع (at the end)
      cell = sheet.getRangeByIndex(headerRow + 1, weekStartCol + 7);
      cell.setText('المجموع');
      cell.cellStyle = verticalGrayHeader;
      sheet
          .getRangeByIndex(
            headerRow + 1,
            weekStartCol + 7,
            headerRow + 2,
            weekStartCol + 7,
          )
          .merge();
    }
    currentRow += 3;

    // =========================================================================
    // MAX SCORES ROW
    // =========================================================================
    sheet.getRangeByIndex(currentRow, serialNumberCol).cellStyle = grayStyle;
    sheet.getRangeByIndex(currentRow, studentNameCol).setText('الدرجة');
    sheet.getRangeByIndex(currentRow, studentNameCol).cellStyle = grayStyle;

    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);

      for (var evalIdx = 0; evalIdx < maxScores.length; evalIdx++) {
        cell = sheet.getRangeByIndex(currentRow, weekStartCol + evalIdx);
        cell.setNumber(maxScores[evalIdx].toDouble());
        cell.cellStyle = (evalIdx % 2 == 0) ? whiteStyle : grayStyle;
      }

      // Total max score (100) at the end
      cell = sheet.getRangeByIndex(currentRow, weekStartCol + 7);
      cell.setNumber(100);
      cell.cellStyle = grayStyle;
    }
    currentRow++;

    // =========================================================================
    // STUDENT DATA ROWS (Force 50 rows)
    // =========================================================================
    for (var i = 0; i < 50; i++) {
      final studentData = i < printData.studentsData.length
          ? printData.studentsData[i]
          : null;

      cell = sheet.getRangeByIndex(currentRow, serialNumberCol);
      cell.setNumber((i + 1).toDouble());
      cell.cellStyle = whiteDataStyle;

      cell = sheet.getRangeByIndex(currentRow, studentNameCol);
      if (studentData != null) {
        cell.setText(studentData.student.name);
      }
      cell.cellStyle = studentNameStyle;

      for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
        final weekNum = weekNumbers[weekIdx];
        final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);

        // Individual scores
        for (var evalIdx = 0; evalIdx < evalIds.length; evalIdx++) {
          final evalId = evalIds[evalIdx];
          cell = sheet.getRangeByIndex(currentRow, weekStartCol + evalIdx);

          if (studentData != null) {
            final score = studentData.getScoreForWeek(weekNum, evalId);
            if (score > 0) cell.setNumber(score.toDouble());
          }
          cell.cellStyle = (evalIdx % 2 == 0) ? whiteDataStyle : grayDataStyle;
        }

        // Total at the end
        cell = sheet.getRangeByIndex(currentRow, weekStartCol + 7);
        if (studentData != null) {
          final weekTotal = studentData.getTotalForWeek(weekNum);
          if (weekTotal > 0) cell.setNumber(weekTotal.toDouble());
        }
        cell.cellStyle = grayDataStyle;
        cell.cellStyle.bold = true;
      }
      currentRow++;
    }

    final int lastStudentRow = currentRow - 1;

    // =========================================================================
    // SIGNATURE SECTION
    // =========================================================================
    currentRow += 2;

    // Calculate center for better positioning
    final int midCol = (4 + (weekNumbers.length * 8)) ~/ 2;

    // Teacher: Closer to center
    final teacherRange = sheet.getRangeByIndex(
      currentRow,
      midCol - 4,
      currentRow,
      midCol - 1,
    );
    teacherRange.merge();
    teacherRange.setText('مدرس المادة: ........................');
    teacherRange.cellStyle.bold = true;
    teacherRange.cellStyle.fontSize = 18;
    teacherRange.cellStyle.hAlign = xlsio.HAlignType.center;

    // Principal: Closer to center
    final principalRange = sheet.getRangeByIndex(
      currentRow,
      midCol + 1,
      currentRow,
      midCol + 4,
    );
    principalRange.merge();
    principalRange.setText('مدير المدرسة: ........................');
    principalRange.cellStyle.bold = true;
    principalRange.cellStyle.fontSize = 18;
    principalRange.cellStyle.hAlign = xlsio.HAlignType.center;

    sheet.getRangeByIndex(currentRow, 1).rowHeight =
        40; // Increase height for clarity

    // =========================================================================
    // SET COLUMN WIDTHS & PAGE SETUP
    // =========================================================================
    sheet.getRangeByIndex(1, serialNumberCol).columnWidth = 6;
    sheet.getRangeByIndex(1, studentNameCol).columnWidth = 40;
    for (var col = firstWeekStartCol; col <= lastTableCol; col++) {
      sheet.getRangeByIndex(1, col).columnWidth = 10;
    }

    // =========================================================================
    // APPLY THICK BORDERS BETWEEN WEEKS
    // =========================================================================
    // Border for student name column (both edges) - using thick for better visibility
    final nameColRange = sheet.getRangeByIndex(
      headerRow,
      studentNameCol,
      lastStudentRow,
      studentNameCol,
    );
    nameColRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thick;
    nameColRange.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thick;

    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);
      final weekEndCol = weekStartCol + weekBlockSize - 1;

      // Wrap each week block in a thick border (right side)
      final weekRange = sheet.getRangeByIndex(
        headerRow,
        weekEndCol, // The "Total" column
        lastStudentRow,
        weekEndCol,
      );
      weekRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thick;
    }

    // Bottom border for the entire table to close it off
    final fullTableBottom = sheet.getRangeByIndex(
      lastStudentRow,
      serialNumberCol,
      lastStudentRow,
      lastTableCol,
    );
    fullTableBottom.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.thick;

    // Set row heights for header rows
    sheet.getRangeByIndex(headerRow, 1).rowHeight = 25; // Week header row
    sheet.getRangeByIndex(headerRow + 1, 1).rowHeight =
        25; // Assessment aspects row
    sheet.getRangeByIndex(headerRow + 2, 1).rowHeight =
        100; // Subject details row (increased for top-to-bottom)

    // Set row heights for student data rows to fill height
    for (int i = headerRow + 3; i <= lastStudentRow; i++) {
      sheet.getRangeByIndex(i, 1).rowHeight = 30;
    }

    sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    sheet.pageSetup.paperSize = xlsio.ExcelPaperSize.paperA4;

    // Set narrow margins to maximize space
    sheet.pageSetup.leftMargin = 0.25;
    sheet.pageSetup.rightMargin = 0.25;
    sheet.pageSetup.topMargin = 0.25;
    sheet.pageSetup.bottomMargin = 0.25;

    sheet.pageSetup.isFitToPage = true;
    sheet.pageSetup.fitToPagesWide = 1;
    sheet.pageSetup.fitToPagesTall = 1;

    final filePath = await _saveAndShareExcelFile(
      workbook.saveAsStream(),
      printData,
    );

    workbook.dispose();
    return filePath;
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

  /// Export an empty attendance sheet matching the template structure
  Future<String> exportEmptyAttendanceSheet(PrintDataEntity printData) async {
    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'كشف الغياب';
      sheet.isRightToLeft = true;

      await _buildEmptyAttendanceStructure(sheet, printData);

      await Future.delayed(Duration.zero);

      final filePath = await _saveEmptySheetFile(
        workbook.saveAsStream(),
        printData,
      );

      workbook.dispose();
      return filePath;
    } catch (e) {
      throw Exception('Failed to export empty attendance sheet: $e');
    }
  }

  /// Build the empty attendance sheet structure matching exact template
  /// Based on XML analysis: B=م, C=الاسم, D-I=Week1, J-O=Week2, P-U=Week3, V-AA=Week4, AB-AG=Week5
  Future<void> _buildEmptyAttendanceStructure(
    xlsio.Worksheet sheet,
    PrintDataEntity printData,
  ) async {
    // Page Setup: Landscape and Fit to Page
    sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    sheet.pageSetup.isFitToPage = true;
    sheet.pageSetup.fitToPagesWide = 1;
    sheet.pageSetup.fitToPagesTall = 1;
    sheet.pageSetup.topMargin = 0.5;
    sheet.pageSetup.bottomMargin = 0.5;
    sheet.pageSetup.leftMargin = 0.5;
    sheet.pageSetup.rightMargin = 0.5;

    final dateFormat = DateFormat('d\\M\\yyyy');
    final weekNumbers = printData.weekNumbers;
    final weekStartDates = printData.weekStartDates ?? {};

    // Row 1: Directorate header (column C, merged across)
    var cell = sheet.getRangeByIndex(1, 3);
    cell.setText(
      'مديرية التربية والتعليم ........................................',
    );
    cell.cellStyle.fontSize = 12;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;

    // Row 2: Administration header
    cell = sheet.getRangeByIndex(2, 3);
    cell.setText('ادارة ........................................');
    cell.cellStyle.fontSize = 12;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;

    // Row 3: School header
    cell = sheet.getRangeByIndex(3, 3);
    cell.setText('مدرسة ........................................');
    cell.cellStyle.fontSize = 12;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;

    // Logo (Other side - Left side)
    // Sheet is RTL, so high column index is Left.
    try {
      List<int> bytes;
      try {
        final ByteData data = await rootBundle.load(
          'assets/images/minist_logo.png',
        );
        bytes = data.buffer.asUint8List();
      } catch (_) {
        // Fallback: Try reading from file directly (useful in debug/simulator if bundle not updated)
        final file = File('assets/images/minist_logo.png');
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          rethrow;
        }
      }

      // Calculate approximate left column based on week count
      // Week 5 ends at column 33 (3 + 5*6).
      // We want it roughly at the start of the last week or slightly before.
      final leftColIndex = 3 + (weekNumbers.length * 6) - 4;

      final picture = sheet.pictures.addStream(1, leftColIndex, bytes);
      picture.height = 90;
      picture.width = 90;
    } catch (e) {
      // Log error but don't fail the whole export, just missing logo
      print('Warning: Failed to add logo to sheet: $e');
      // For now, let's rethrow to see it in the UI if the user is failing entirely
      // throw Exception('Logo load failed: $e');
      // Actually, keep it non-fatal but log it clearly.
    }

    // Row 4: Title (columns F-K merged) and Subject (columns Q-T merged)
    // Title: سجل رصد غياب فصل
    cell = sheet.getRangeByIndex(4, 6);
    cell.setText('سجل رصد غياب فصل           /');
    cell.cellStyle.fontSize = 13;
    cell.cellStyle.bold = true;
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(4, 6, 4, 11).merge();

    // Subject: مادة
    cell = sheet.getRangeByIndex(4, 17);
    cell.setText('مادة : ..................');
    cell.cellStyle.fontSize = 13;
    cell.cellStyle.bold = true;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(4, 17, 4, 20).merge();

    // Set row height for title/subject row
    sheet.getRangeByIndex(4, 1).rowHeight = 35;

    // Row 5: Week headers (merged across 6 days each)
    // Row 6: Day sub-headers
    // Column B (2): م, Column C (3): الاسم, Columns D+ (4+): week days

    // "م" column header (B5:B6 merged)
    var range = sheet.getRangeByIndex(5, 2, 6, 2);
    range.merge();
    range.setText('م');
    _styleEmptySheetHeaderCell(range);

    // "الاسم" column header (C5:C6 merged)
    range = sheet.getRangeByIndex(5, 3, 6, 3);
    range.merge();
    range.setText('الاســـــــــــــــــــــــــــــــم');
    _styleEmptySheetHeaderCell(range);

    // Week headers and day sub-headers (starting from column D = 4)
    final dayNames = [
      'السبت',
      'الاحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
    ];
    int col = 4; // Start at column D

    for (final weekNum in weekNumbers) {
      final startCol = col;
      final endCol = col + 5; // 6 days

      // Week header (row 5, merged across 6 columns)
      range = sheet.getRangeByIndex(5, startCol, 5, endCol);
      range.merge();

      final weekStartDate = weekStartDates[weekNum];
      String weekLabel = 'الأسبوع ${_getArabicOrdinal(weekNum)}';
      if (weekStartDate != null) {
        weekLabel += ' ${dateFormat.format(weekStartDate)}';
      }
      range.setText(weekLabel);
      _styleEmptySheetHeaderCell(range);

      // Day sub-headers (row 6)
      for (var i = 0; i < 6; i++) {
        cell = sheet.getRangeByIndex(6, col + i);
        cell.setText(dayNames[i]);
        _styleEmptySheetSubHeaderCell(cell);

        // Alternating colors
        if (i % 2 != 0) {
          cell.cellStyle.backColor = '#D9D9D9';
        }

        // Thick border between weeks
        if (i == 5) {
          cell.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thick;
        }
      }

      col = endCol + 1;
    }

    await Future.delayed(Duration.zero);

    // Student data rows (starting from row 7)
    // Use existing students or default to 50 blank rows
    final studentCount = printData.studentsData.isEmpty
        ? 50
        : printData.studentsData.length;

    int rowIndex = 7;
    for (var i = 0; i < studentCount; i++) {
      // Student number (column B)
      cell = sheet.getRangeByIndex(rowIndex, 2);
      cell.setNumber((i + 1).toDouble());
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      _addBorder(cell);

      // Student name (column C) - empty or from data
      cell = sheet.getRangeByIndex(rowIndex, 3);
      if (printData.studentsData.isNotEmpty &&
          i < printData.studentsData.length) {
        cell.setText(printData.studentsData[i].student.name);
      } else {
        cell.setText(''); // Empty for blank template
      }
      cell.cellStyle.hAlign = xlsio.HAlignType.right;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      _addBorder(cell);

      // Empty attendance cells for each week (6 days * number of weeks)
      int dataCol = 4; // Start at column D
      for (final _ in weekNumbers) {
        for (var d = 0; d < 6; d++) {
          cell = sheet.getRangeByIndex(rowIndex, dataCol);
          cell.setText(''); // Empty cell for manual entry
          cell.cellStyle.hAlign = xlsio.HAlignType.center;
          cell.cellStyle.vAlign = xlsio.VAlignType.center;
          _addBorder(cell);

          // Alternating colors
          if (d % 2 != 0) {
            cell.cellStyle.backColor = '#D9D9D9';
          }

          // Thick border between weeks (last column of week)
          if (d == 5) {
            cell.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thick;
          }

          dataCol++;
        }
      }

      rowIndex++;

      // Yield every 10 students
      if (i % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    // Set column widths to match template
    sheet.getRangeByIndex(1, 2).columnWidth = 4; // م column narrow
    sheet.getRangeByIndex(1, 3).columnWidth = 30; // Name column wider
    for (var c = 4; c <= 3 + (weekNumbers.length * 6); c++) {
      sheet.getRangeByIndex(1, c).columnWidth = 5; // Day columns narrow
    }

    // Set row heights for header rows
    sheet.getRangeByIndex(5, 1).rowHeight = 30;
    sheet.getRangeByIndex(6, 1).rowHeight = 80;
  }

  /// Style for empty sheet header cells
  void _styleEmptySheetHeaderCell(xlsio.Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.fontSize = 11;
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cell.cellStyle.borders.all.color = '#000000';
  }

  /// Style for empty sheet sub-header cells (day names)
  void _styleEmptySheetSubHeaderCell(xlsio.Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.fontSize = 9;
    cell.cellStyle.rotation = 180;
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cell.cellStyle.borders.all.color = '#000000';
  }

  /// Add border to cell
  void _addBorder(xlsio.Range cell) {
    cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cell.cellStyle.borders.all.color = '#000000';
  }

  /// Build the styled attendance sheet structure with actual data
  Future<void> _buildStyledAttendanceStructure(
    xlsio.Worksheet sheet,
    PrintDataEntity printData,
  ) async {
    // Page Setup: Landscape and Fit to Page
    sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    sheet.pageSetup.isFitToPage = true;
    sheet.pageSetup.fitToPagesWide = 1;
    sheet.pageSetup.fitToPagesTall = 1;
    sheet.pageSetup.topMargin = 0.5;
    sheet.pageSetup.bottomMargin = 0.5;
    sheet.pageSetup.leftMargin = 0.5;
    sheet.pageSetup.rightMargin = 0.5;

    final dateFormat = DateFormat('d\\M\\yyyy');
    final weekNumbers = printData.weekNumbers;
    final weekStartDates = printData.weekStartDates ?? {};

    // Row 1: Directorate header
    var cell = sheet.getRangeByIndex(1, 3);
    cell.setText('مديرية التربية والتعليم ${printData.governorate}');
    cell.cellStyle.fontSize = 12;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;
    cell.cellStyle.fontColor = '#000000';
    sheet.getRangeByIndex(1, 1).rowHeight = 25;

    // Row 2: Administration header
    cell = sheet.getRangeByIndex(2, 3);
    cell.setText('ادارة ${printData.administration}');
    cell.cellStyle.fontSize = 12;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;
    cell.cellStyle.fontColor = '#000000';
    sheet.getRangeByIndex(2, 1).rowHeight = 25;

    // Row 3: School header
    cell = sheet.getRangeByIndex(3, 3);
    cell.setText('مدرسة ${printData.classEntity.school}');
    cell.cellStyle.fontSize = 12;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;
    cell.cellStyle.fontColor = '#000000';
    sheet.getRangeByIndex(3, 1).rowHeight = 25;

    // Logo
    try {
      List<int> bytes;
      try {
        final ByteData data = await rootBundle.load(
          'assets/images/minist_logo.png',
        );
        bytes = data.buffer.asUint8List();
      } catch (_) {
        final file = File('assets/images/minist_logo.png');
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          rethrow;
        }
      }

      final leftColIndex = 3 + (weekNumbers.length * 6) - 4;
      final picture = sheet.pictures.addStream(1, leftColIndex, bytes);
      picture.height = 90;
      picture.width = 90;
    } catch (e) {
      print('Warning: Failed to add logo to sheet: $e');
    }

    // Row 4: Title and Subject
    cell = sheet.getRangeByIndex(4, 6);
    cell.setText('سجل رصد غياب فصل           ${printData.classEntity.name}');
    cell.cellStyle.fontSize = 13;
    cell.cellStyle.bold = true;
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(4, 6, 4, 11).merge();

    cell = sheet.getRangeByIndex(4, 17);
    cell.setText('مادة : ${printData.classEntity.subject}');
    cell.cellStyle.fontSize = 13;
    cell.cellStyle.bold = true;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(4, 17, 4, 20).merge();

    sheet.getRangeByIndex(4, 1).rowHeight = 35;

    // Row 5 & 6: Headers
    var range = sheet.getRangeByIndex(5, 2, 6, 2);
    range.merge();
    range.setText('م');
    _styleEmptySheetHeaderCell(range);

    range = sheet.getRangeByIndex(5, 3, 6, 3);
    range.merge();
    range.setText('الاســـــــــــــــــــــــــــــــم');
    _styleEmptySheetHeaderCell(range);

    final dayNames = [
      'السبت',
      'الاحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
    ];
    int col = 4;

    for (final weekNum in weekNumbers) {
      final startCol = col;
      final endCol = col + 5;

      range = sheet.getRangeByIndex(5, startCol, 5, endCol);
      range.merge();

      final weekStartDate = weekStartDates[weekNum];
      String weekLabel = 'الأسبوع ${_getArabicOrdinal(weekNum)}';
      if (weekStartDate != null) {
        weekLabel += ' ${dateFormat.format(weekStartDate)}';
      }
      range.setText(weekLabel);
      _styleEmptySheetHeaderCell(range);

      for (var i = 0; i < 6; i++) {
        cell = sheet.getRangeByIndex(6, col + i);
        cell.setText(dayNames[i]);
        _styleEmptySheetSubHeaderCell(cell);

        if (i % 2 != 0) {
          cell.cellStyle.backColor = '#D9D9D9';
        }

        if (i == 5) {
          cell.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thick;
        }
      }
      col = endCol + 1;
    }

    await Future.delayed(Duration.zero);

    // Data Rows
    int rowIndex = 7;
    for (var i = 0; i < printData.studentsData.length; i++) {
      final studentData = printData.studentsData[i];

      // Number
      cell = sheet.getRangeByIndex(rowIndex, 2);
      cell.setNumber((i + 1).toDouble());
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      _addBorder(cell);

      // Name
      cell = sheet.getRangeByIndex(rowIndex, 3);
      cell.setText(studentData.student.name);
      cell.cellStyle.hAlign = xlsio.HAlignType.right;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      _addBorder(cell);

      // Attendance
      int dataCol = 4;
      for (final weekNum in weekNumbers) {
        final weekStartDate = weekStartDates[weekNum];
        final weekDays = weekStartDate != null
            ? WeekHelper.getWeekDays(weekStartDate)
            : <DateTime>[];

        for (var d = 0; d < 6; d++) {
          cell = sheet.getRangeByIndex(rowIndex, dataCol);

          // Default alternating background
          if (d % 2 != 0) {
            cell.cellStyle.backColor = '#D9D9D9';
          }

          if (weekDays.isNotEmpty && d < weekDays.length) {
            final day = weekDays[d];
            final status = studentData.getAttendanceForWeekDate(weekNum, day);
            if (status != null) {
              cell.setText(_getAttendanceStatusSymbol(status));
              _styleAttendanceCell(cell, status);
            }
          }

          cell.cellStyle.hAlign = xlsio.HAlignType.center;
          cell.cellStyle.vAlign = xlsio.VAlignType.center;
          _addBorder(cell);

          if (d == 5) {
            cell.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thick;
          }

          dataCol++;
        }
      }

      rowIndex++;
      if (i % 10 == 0) await Future.delayed(Duration.zero);
    }

    // Column widths
    sheet.getRangeByIndex(1, 2).columnWidth = 4;
    sheet.getRangeByIndex(1, 3).columnWidth = 30;
    for (var c = 4; c <= 3 + (weekNumbers.length * 6); c++) {
      sheet.getRangeByIndex(1, c).columnWidth = 5;
    }

    // Header Heights
    sheet.getRangeByIndex(5, 1).rowHeight = 30;
    sheet.getRangeByIndex(6, 1).rowHeight = 80;
  }

  /// Save empty sheet file
  Future<String> _saveEmptySheetFile(
    List<int> fileBytes,
    PrintDataEntity printData,
  ) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final className = printData.classEntity.name.replaceAll('/', '_');
      final filename = 'empty_attendance_${className}_$timestamp.xlsx';

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
      throw Exception('Failed to save empty sheet file: $e');
    }
  }

  /// Export primary (3-6) scores by creating Excel from scratch with proper styling
  Future<String> _exportFromPrimaryTemplate(PrintDataEntity printData) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'كشف درجات 3-6';
    sheet.isRightToLeft = true; // RTL for Arabic layout

    // Configuration constants
    const int weekBlockSize = 6; // 1 total + 5 evaluations per week
    const int firstWeekStartCol = 4; // Column D (Shifted from C)
    const int serialNumberCol = 2; // Column B (Shifted from A)
    const int studentNameCol = 3; // Column C (Shifted from B)

    // Evaluation IDs (Primary 3-6)
    // Ordered: Homework, Activity, Weekly, Performance, Attendance
    final evalIds = [
      'primary_homework',
      'primary_activity',
      'primary_weekly',
      'primary_performance',
      'primary_attendance',
    ];

    // Headers for the evaluations
    // Matches template exactly
    final subNames = [
      'كراس الواجب',
      'كراس النشاط',
      'تقييم أسبوعى',
      'المهام الادائية',
      'المواظبة والسلوك',
    ];

    // Max scores: 5, 5, 5, 10, 5 = 30
    final maxScores = [5, 5, 5, 10, 5];

    final weekNumbers = printData.weekNumbers;
    final dateFormat = DateFormat('yyyy\\M\\d');

    // =========================================================================
    // DEFINE STYLES
    // =========================================================================

    // Base header style
    final baseHeaderStyle = workbook.styles.add('BaseHeaderStylePrimary');
    baseHeaderStyle.bold = true;
    baseHeaderStyle.fontSize = 12;
    baseHeaderStyle.hAlign = xlsio.HAlignType.center;
    baseHeaderStyle.vAlign = xlsio.VAlignType.center;
    baseHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    baseHeaderStyle.borders.all.color = '#000000';

    // Week header style
    final weekHeaderStyle = workbook.styles.add('WeekHeaderStylePrimary');
    weekHeaderStyle.backColor = '#FFFFFF';
    weekHeaderStyle.bold = true;
    weekHeaderStyle.fontSize = 14;
    weekHeaderStyle.hAlign = xlsio.HAlignType.center;
    weekHeaderStyle.vAlign = xlsio.VAlignType.center;
    weekHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    weekHeaderStyle.borders.all.color = '#000000';

    // Vertical Headers
    final verticalGrayHeader = workbook.styles.add('VerticalGrayHeaderPrimary');
    verticalGrayHeader.backColor = '#D9D9D9';
    verticalGrayHeader.hAlign = xlsio.HAlignType.center;
    verticalGrayHeader.vAlign = xlsio.VAlignType.center;
    verticalGrayHeader.borders.all.lineStyle = xlsio.LineStyle.thin;
    verticalGrayHeader.borders.all.color = '#000000';
    verticalGrayHeader.rotation = 180;
    verticalGrayHeader.bold = true;
    verticalGrayHeader.fontSize = 14;

    final verticalWhiteHeader = workbook.styles.add(
      'VerticalWhiteHeaderPrimary',
    );
    verticalWhiteHeader.backColor = '#FFFFFF';
    verticalWhiteHeader.hAlign = xlsio.HAlignType.center;
    verticalWhiteHeader.vAlign = xlsio.VAlignType.center;
    verticalWhiteHeader.borders.all.lineStyle = xlsio.LineStyle.thin;
    verticalWhiteHeader.borders.all.color = '#000000';
    verticalWhiteHeader.rotation = 180;
    verticalWhiteHeader.bold = true;
    verticalWhiteHeader.fontSize = 14;

    // Student name style
    final studentNameStyle = workbook.styles.add('StudentNameStylePrimary');
    studentNameStyle.hAlign = xlsio.HAlignType.right;
    studentNameStyle.vAlign = xlsio.VAlignType.center;
    studentNameStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    studentNameStyle.borders.all.color = '#000000';
    studentNameStyle.fontSize = 15;
    studentNameStyle.bold = true;

    // Data cell styles
    final grayDataStyle = workbook.styles.add('GrayDataStylePrimary');
    grayDataStyle.backColor = '#D9D9D9';
    grayDataStyle.hAlign = xlsio.HAlignType.center;
    grayDataStyle.vAlign = xlsio.VAlignType.center;
    grayDataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    grayDataStyle.borders.all.color = '#000000';
    grayDataStyle.fontSize = 14;
    grayDataStyle.bold = true;

    final whiteDataStyle = workbook.styles.add('WhiteDataStylePrimary');
    whiteDataStyle.backColor = '#FFFFFF';
    whiteDataStyle.hAlign = xlsio.HAlignType.center;
    whiteDataStyle.vAlign = xlsio.VAlignType.center;
    whiteDataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    whiteDataStyle.borders.all.color = '#000000';
    whiteDataStyle.fontSize = 14;
    whiteDataStyle.bold = true;

    // Gray Style for simple headers
    final grayStyle = workbook.styles.add('GrayStylePrimary');
    grayStyle.backColor = '#D9D9D9';
    grayStyle.hAlign = xlsio.HAlignType.center;
    grayStyle.vAlign = xlsio.VAlignType.center;
    grayStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    grayStyle.borders.all.color = '#000000';
    grayStyle.fontSize = 14;
    grayStyle.bold = true;

    final whiteStyle = workbook.styles.add('WhiteStylePrimary');
    whiteStyle.backColor = '#FFFFFF';
    whiteStyle.hAlign = xlsio.HAlignType.center;
    whiteStyle.vAlign = xlsio.VAlignType.center;
    whiteStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    whiteStyle.borders.all.color = '#000000';
    whiteStyle.fontSize = 14;
    whiteStyle.bold = true;

    // =========================================================================
    // HEADER SECTION
    // =========================================================================
    int currentRow = 1;
    final int lastTableCol =
        firstWeekStartCol + (weekNumbers.length * weekBlockSize) - 1;
    xlsio.Range cell;

    // 1. Logo
    try {
      final ByteData logoData = await rootBundle.load(
        'assets/images/minist_logo.png',
      );
      final List<int> bytes = logoData.buffer.asUint8List();
      final int logoCol = (lastTableCol > 10) ? lastTableCol - 1 : 10;
      final xlsio.Picture picture = sheet.pictures.addStream(
        currentRow,
        logoCol,
        bytes,
      );
      picture.height = 85;
      picture.width = 85;
    } catch (e) {
      // ignore
    }

    // 2. Metadata
    void setLeftHeaderCell(int row, String text) {
      final c = sheet.getRangeByIndex(row, 1, row, 10);
      c.merge();
      c.setText(text);
      c.cellStyle.fontSize = 14;
      c.cellStyle.hAlign = xlsio.HAlignType.center;
      c.cellStyle.bold = true;
      sheet.getRangeByIndex(row, 1).rowHeight = 30;
    }

    setLeftHeaderCell(
      currentRow++,
      'مديرية التربية والتعليم ${printData.governorate}',
    );
    setLeftHeaderCell(currentRow++, 'إدارة ${printData.administration}');
    setLeftHeaderCell(currentRow++, 'مدرسة ${printData.classEntity.school}');

    // 3. Title row
    final rowRange = sheet.getRangeByIndex(
      currentRow,
      1,
      currentRow,
      lastTableCol,
    );
    rowRange.merge();
    rowRange.setText(
      'سجل رصد درجات فصل  ${printData.classEntity.grade}                                               مادة : ${printData.classEntity.subject}',
    );
    rowRange.cellStyle.bold = true;
    rowRange.cellStyle.fontSize = 18;
    rowRange.cellStyle.hAlign = xlsio.HAlignType.center;
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 40;

    currentRow += 2;

    // =========================================================================
    // TABLE HEADERS
    // =========================================================================
    int headerRow = currentRow;

    // م and الاسم
    cell = sheet.getRangeByIndex(headerRow, serialNumberCol);
    cell.setText('م');
    cell.cellStyle = baseHeaderStyle;
    cell.cellStyle.backColor = '#D9D9D9';
    sheet
        .getRangeByIndex(
          headerRow,
          serialNumberCol,
          headerRow + 2, // Spans 3 rows
          serialNumberCol,
        )
        .merge();

    cell = sheet.getRangeByIndex(headerRow, studentNameCol);
    cell.setText('الاسم');
    cell.cellStyle = baseHeaderStyle;
    sheet
        .getRangeByIndex(
          headerRow,
          studentNameCol,
          headerRow + 2, // Spans 3 rows
          studentNameCol,
        )
        .merge();

    // Week headers
    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekNum = weekNumbers[weekIdx];
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);
      final weekEndCol = weekStartCol + weekBlockSize - 1;

      String weekLabel = 'الأسبوع ${_getArabicOrdinal(weekNum)}';
      final DateTime baseStartDate = DateTime(2026, 2, 7);
      final DateTime weekStartDate = baseStartDate.add(
        Duration(days: weekIdx * 7),
      );
      weekLabel += ' ${dateFormat.format(weekStartDate)}';

      cell = sheet.getRangeByIndex(headerRow, weekStartCol);
      cell.setText(weekLabel);
      cell.cellStyle = weekHeaderStyle;
      sheet
          .getRangeByIndex(headerRow, weekStartCol, headerRow, weekEndCol)
          .merge();

      // Row 2: Evaluation Sub-Headers
      // Columns: Homework, Activity, Weekly, Performance, Attendance, Total
      for (var sIdx = 0; sIdx < subNames.length; sIdx++) {
        cell = sheet.getRangeByIndex(headerRow + 1, weekStartCol + sIdx);
        cell.setText(subNames[sIdx]);
        cell.cellStyle = (sIdx % 2 == 0)
            ? verticalWhiteHeader
            : verticalGrayHeader;

        sheet
            .getRangeByIndex(
              headerRow + 1,
              weekStartCol + sIdx,
              headerRow + 2,
              weekStartCol + sIdx,
            )
            .merge();
      }

      // Total Column (last one)
      cell = sheet.getRangeByIndex(headerRow + 1, weekStartCol + 5);
      cell.setText('المجموع');
      cell.cellStyle = verticalGrayHeader;
      sheet
          .getRangeByIndex(
            headerRow + 1,
            weekStartCol + 5,
            headerRow + 2,
            weekStartCol + 5,
          )
          .merge();
    }
    currentRow += 3;

    // =========================================================================
    // MAX SCORES ROW
    // =========================================================================
    sheet.getRangeByIndex(currentRow, serialNumberCol).cellStyle = grayStyle;
    sheet.getRangeByIndex(currentRow, studentNameCol).setText('الدرجة');
    sheet.getRangeByIndex(currentRow, studentNameCol).cellStyle = grayStyle;

    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);

      for (var evalIdx = 0; evalIdx < maxScores.length; evalIdx++) {
        cell = sheet.getRangeByIndex(currentRow, weekStartCol + evalIdx);
        cell.setNumber(maxScores[evalIdx].toDouble());
        cell.cellStyle = (evalIdx % 2 == 0) ? whiteStyle : grayStyle;
      }

      // Total max score (30)
      cell = sheet.getRangeByIndex(currentRow, weekStartCol + 5);
      cell.setNumber(30);
      cell.cellStyle = grayStyle;
    }
    currentRow++;

    // =========================================================================
    // STUDENT DATA ROWS
    // =========================================================================
    for (var i = 0; i < 50; i++) {
      final studentData = i < printData.studentsData.length
          ? printData.studentsData[i]
          : null;

      cell = sheet.getRangeByIndex(currentRow, serialNumberCol);
      cell.setNumber((i + 1).toDouble());
      cell.cellStyle = whiteDataStyle;

      cell = sheet.getRangeByIndex(currentRow, studentNameCol);
      if (studentData != null) {
        cell.setText(studentData.student.name);
      }
      cell.cellStyle = studentNameStyle;

      for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
        final weekNum = weekNumbers[weekIdx];
        final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);

        // Individual scores
        for (var evalIdx = 0; evalIdx < evalIds.length; evalIdx++) {
          final evalId = evalIds[evalIdx];
          cell = sheet.getRangeByIndex(currentRow, weekStartCol + evalIdx);

          if (studentData != null) {
            final score = studentData.getScoreForWeek(weekNum, evalId);
            if (score > 0) cell.setNumber(score.toDouble());
          }
          cell.cellStyle = (evalIdx % 2 == 0) ? whiteDataStyle : grayDataStyle;
        }

        // Total at the end
        cell = sheet.getRangeByIndex(currentRow, weekStartCol + 5);
        if (studentData != null) {
          // Calculate local total for this template
          int weekTotal = 0;
          for (var evalId in evalIds) {
            weekTotal += studentData.getScoreForWeek(weekNum, evalId);
          }
          if (weekTotal > 0) cell.setNumber(weekTotal.toDouble());
        }
        cell.cellStyle = grayDataStyle;
        cell.cellStyle.bold = true;
      }
      currentRow++;
    }

    final int lastStudentRow = currentRow - 1;

    // =========================================================================
    // SIGNATURE SECTION
    // =========================================================================
    currentRow += 2;

    // Calculate center for better positioning
    final int midCol = (firstWeekStartCol + lastTableCol) ~/ 2;

    // Teacher: Closer to center
    final teacherRange = sheet.getRangeByIndex(
      currentRow,
      midCol - 4,
      currentRow,
      midCol - 1,
    );
    teacherRange.merge();
    teacherRange.setText('مدرس المادة: ........................');
    teacherRange.cellStyle.bold = true;
    teacherRange.cellStyle.fontSize = 18;
    teacherRange.cellStyle.hAlign = xlsio.HAlignType.center;

    // Principal: Closer to center
    final principalRange = sheet.getRangeByIndex(
      currentRow,
      midCol + 1,
      currentRow,
      midCol + 4,
    );
    principalRange.merge();
    principalRange.setText('مدير المدرسة: ........................');
    principalRange.cellStyle.bold = true;
    principalRange.cellStyle.fontSize = 18;
    principalRange.cellStyle.hAlign = xlsio.HAlignType.center;

    sheet.getRangeByIndex(currentRow, 1).rowHeight =
        40; // Increase height for clarity

    // =========================================================================
    // SET COLUMN WIDTHS & BORDERS
    // =========================================================================
    sheet.getRangeByIndex(1, 1).columnWidth = 2; // Margin column
    sheet.getRangeByIndex(1, serialNumberCol).columnWidth = 6;
    sheet.getRangeByIndex(1, studentNameCol).columnWidth = 40;
    for (var col = firstWeekStartCol; col <= lastTableCol; col++) {
      sheet.getRangeByIndex(1, col).columnWidth = 10;
    }

    // Name column border
    final nameColRange = sheet.getRangeByIndex(
      headerRow,
      studentNameCol,
      lastStudentRow,
      studentNameCol,
    );
    nameColRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thick;
    nameColRange.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thick;

    // Week borders
    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);
      final weekEndCol = weekStartCol + weekBlockSize - 1;

      final weekRange = sheet.getRangeByIndex(
        headerRow,
        weekEndCol,
        lastStudentRow,
        weekEndCol,
      );
      weekRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thick;
    }

    final fullTableBottom = sheet.getRangeByIndex(
      lastStudentRow,
      serialNumberCol,
      lastStudentRow,
      lastTableCol,
    );
    fullTableBottom.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.thick;

    // Row heights
    sheet.getRangeByIndex(headerRow, 1).rowHeight = 30; // Week header
    sheet.getRangeByIndex(headerRow + 1, 1).rowHeight = 110; // Vertical text

    for (int i = headerRow + 3; i <= lastStudentRow; i++) {
      sheet.getRangeByIndex(i, 1).rowHeight = 30;
    }

    sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    sheet.pageSetup.paperSize = xlsio.ExcelPaperSize.paperA4;
    sheet.pageSetup.leftMargin = 0.25;
    sheet.pageSetup.rightMargin = 0.25;
    sheet.pageSetup.topMargin = 0.25;
    sheet.pageSetup.bottomMargin = 0.25;
    sheet.pageSetup.isFitToPage = true;
    sheet.pageSetup.fitToPagesWide = 1;
    sheet.pageSetup.fitToPagesTall = 1;

    final filePath = await _saveAndShareExcelFile(
      workbook.saveAsStream(),
      printData,
    );

    workbook.dispose();
    return filePath;
  }

  /// Export secondary (Preparatory 1-2) scores by creating Excel from scratch with proper styling
  Future<String> _exportFromSecondaryTemplate(PrintDataEntity printData) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'كشف درجات 1-2 اعدادي';
    sheet.isRightToLeft = true; // RTL for Arabic layout

    // Configuration constants
    const int weekBlockSize = 6; // 1 total + 5 evaluations per week
    const int firstWeekStartCol = 4; // Column D
    const int serialNumberCol = 2; // Column B
    const int studentNameCol = 3; // Column C

    // Evaluation IDs (Preparatory/Secondary)
    // Ordered: Homework, Activity, Weekly, Performance, Attendance
    final evalIds = [
      'secondary_homework',
      'secondary_activity',
      'secondary_weekly',
      'secondary_performance',
      'secondary_attendance',
    ];

    // Headers for the evaluations
    // Matches template exactly (Same as Primary as requested)
    final subNames = [
      'كراس الواجب',
      'كراس النشاط',
      'تقييم أسبوعى',
      'المهام الادائية',
      'المواظبة والسلوك',
    ];

    // Max scores: 5, 5, 5, 10, 5 = 30 (Same as Primary as requested)
    final maxScores = [5, 5, 5, 10, 5];

    final weekNumbers = printData.weekNumbers;
    final dateFormat = DateFormat('yyyy\\M\\d');

    // =========================================================================
    // DEFINE STYLES
    // =========================================================================

    // Base header style
    final baseHeaderStyle = workbook.styles.add('BaseHeaderStyleSecondary');
    baseHeaderStyle.bold = true;
    baseHeaderStyle.fontSize = 12;
    baseHeaderStyle.hAlign = xlsio.HAlignType.center;
    baseHeaderStyle.vAlign = xlsio.VAlignType.center;
    baseHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    baseHeaderStyle.borders.all.color = '#000000';

    // Week header style
    final weekHeaderStyle = workbook.styles.add('WeekHeaderStyleSecondary');
    weekHeaderStyle.backColor = '#FFFFFF';
    weekHeaderStyle.bold = true;
    weekHeaderStyle.fontSize = 14;
    weekHeaderStyle.hAlign = xlsio.HAlignType.center;
    weekHeaderStyle.vAlign = xlsio.VAlignType.center;
    weekHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    weekHeaderStyle.borders.all.color = '#000000';

    // Vertical Headers
    final verticalGrayHeader = workbook.styles.add(
      'VerticalGrayHeaderSecondary',
    );
    verticalGrayHeader.backColor = '#D9D9D9';
    verticalGrayHeader.hAlign = xlsio.HAlignType.center;
    verticalGrayHeader.vAlign = xlsio.VAlignType.center;
    verticalGrayHeader.borders.all.lineStyle = xlsio.LineStyle.thin;
    verticalGrayHeader.borders.all.color = '#000000';
    verticalGrayHeader.rotation = 180;
    verticalGrayHeader.bold = true;
    verticalGrayHeader.fontSize = 14;

    final verticalWhiteHeader = workbook.styles.add(
      'VerticalWhiteHeaderSecondary',
    );
    verticalWhiteHeader.backColor = '#FFFFFF';
    verticalWhiteHeader.hAlign = xlsio.HAlignType.center;
    verticalWhiteHeader.vAlign = xlsio.VAlignType.center;
    verticalWhiteHeader.borders.all.lineStyle = xlsio.LineStyle.thin;
    verticalWhiteHeader.borders.all.color = '#000000';
    verticalWhiteHeader.rotation = 180;
    verticalWhiteHeader.bold = true;
    verticalWhiteHeader.fontSize = 14;

    // Student name style
    final studentNameStyle = workbook.styles.add('StudentNameStyleSecondary');
    studentNameStyle.hAlign = xlsio.HAlignType.right;
    studentNameStyle.vAlign = xlsio.VAlignType.center;
    studentNameStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    studentNameStyle.borders.all.color = '#000000';
    studentNameStyle.fontSize = 15;
    studentNameStyle.bold = true;

    // Data cell styles
    final grayDataStyle = workbook.styles.add('GrayDataStyleSecondary');
    grayDataStyle.backColor = '#D9D9D9';
    grayDataStyle.hAlign = xlsio.HAlignType.center;
    grayDataStyle.vAlign = xlsio.VAlignType.center;
    grayDataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    grayDataStyle.borders.all.color = '#000000';
    grayDataStyle.fontSize = 14;
    grayDataStyle.bold = true;

    final whiteDataStyle = workbook.styles.add('WhiteDataStyleSecondary');
    whiteDataStyle.backColor = '#FFFFFF';
    whiteDataStyle.hAlign = xlsio.HAlignType.center;
    whiteDataStyle.vAlign = xlsio.VAlignType.center;
    whiteDataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    whiteDataStyle.borders.all.color = '#000000';
    whiteDataStyle.fontSize = 14;
    whiteDataStyle.bold = true;

    // Gray Style for simple headers
    final grayStyle = workbook.styles.add('GrayStyleSecondary');
    grayStyle.backColor = '#D9D9D9';
    grayStyle.hAlign = xlsio.HAlignType.center;
    grayStyle.vAlign = xlsio.VAlignType.center;
    grayStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    grayStyle.borders.all.color = '#000000';
    grayStyle.fontSize = 14;
    grayStyle.bold = true;

    final whiteStyle = workbook.styles.add('WhiteStyleSecondary');
    whiteStyle.backColor = '#FFFFFF';
    whiteStyle.hAlign = xlsio.HAlignType.center;
    whiteStyle.vAlign = xlsio.VAlignType.center;
    whiteStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    whiteStyle.borders.all.color = '#000000';
    whiteStyle.fontSize = 14;
    whiteStyle.bold = true;

    // =========================================================================
    // HEADER SECTION
    // =========================================================================
    int currentRow = 1;
    final int lastTableCol =
        firstWeekStartCol + (weekNumbers.length * weekBlockSize) - 1;
    xlsio.Range cell;

    // 1. Logo
    try {
      final ByteData logoData = await rootBundle.load(
        'assets/images/minist_logo.png',
      );
      final List<int> bytes = logoData.buffer.asUint8List();
      final int logoCol = (lastTableCol > 10) ? lastTableCol - 1 : 10;
      final xlsio.Picture picture = sheet.pictures.addStream(
        currentRow,
        logoCol,
        bytes,
      );
      picture.height = 85;
      picture.width = 85;
    } catch (e) {
      // ignore
    }

    // 2. Metadata
    void setLeftHeaderCell(int row, String text) {
      final c = sheet.getRangeByIndex(row, 1, row, 10);
      c.merge();
      c.setText(text);
      c.cellStyle.fontSize = 14;
      c.cellStyle.hAlign = xlsio.HAlignType.center;
      c.cellStyle.bold = true;
      sheet.getRangeByIndex(row, 1).rowHeight = 30;
    }

    setLeftHeaderCell(
      currentRow++,
      'مديرية التربية والتعليم ${printData.governorate}',
    );
    setLeftHeaderCell(currentRow++, 'إدارة ${printData.administration}');
    setLeftHeaderCell(currentRow++, 'مدرسة ${printData.classEntity.school}');

    // 3. Title row
    final rowRange = sheet.getRangeByIndex(
      currentRow,
      1,
      currentRow,
      lastTableCol,
    );
    rowRange.merge();
    rowRange.setText(
      'سجل رصد درجات فصل  ${printData.classEntity.grade}                                               مادة : ${printData.classEntity.subject}',
    );
    rowRange.cellStyle.bold = true;
    rowRange.cellStyle.fontSize = 18;
    rowRange.cellStyle.hAlign = xlsio.HAlignType.center;
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 40;

    currentRow += 2;

    // =========================================================================
    // TABLE HEADERS
    // =========================================================================
    int headerRow = currentRow;

    // م and الاسم
    cell = sheet.getRangeByIndex(headerRow, serialNumberCol);
    cell.setText('م');
    cell.cellStyle = baseHeaderStyle;
    cell.cellStyle.backColor = '#D9D9D9';
    sheet
        .getRangeByIndex(
          headerRow,
          serialNumberCol,
          headerRow + 2, // Spans 3 rows
          serialNumberCol,
        )
        .merge();

    cell = sheet.getRangeByIndex(headerRow, studentNameCol);
    cell.setText('الاسم');
    cell.cellStyle = baseHeaderStyle;
    sheet
        .getRangeByIndex(
          headerRow,
          studentNameCol,
          headerRow + 2, // Spans 3 rows
          studentNameCol,
        )
        .merge();

    // Week headers
    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekNum = weekNumbers[weekIdx];
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);
      final weekEndCol = weekStartCol + weekBlockSize - 1;

      String weekLabel = 'الأسبوع ${_getArabicOrdinal(weekNum)}';
      final DateTime baseStartDate = DateTime(2026, 2, 7);
      final DateTime weekStartDate = baseStartDate.add(
        Duration(days: weekIdx * 7),
      );
      weekLabel += ' ${dateFormat.format(weekStartDate)}';

      cell = sheet.getRangeByIndex(headerRow, weekStartCol);
      cell.setText(weekLabel);
      cell.cellStyle = weekHeaderStyle;
      sheet
          .getRangeByIndex(headerRow, weekStartCol, headerRow, weekEndCol)
          .merge();

      // Row 2: Evaluation Sub-Headers
      // Columns: Homework, Activity, Weekly, Performance, Attendance, Total
      for (var sIdx = 0; sIdx < subNames.length; sIdx++) {
        cell = sheet.getRangeByIndex(headerRow + 1, weekStartCol + sIdx);
        cell.setText(subNames[sIdx]);
        cell.cellStyle = (sIdx % 2 == 0)
            ? verticalWhiteHeader
            : verticalGrayHeader;

        sheet
            .getRangeByIndex(
              headerRow + 1,
              weekStartCol + sIdx,
              headerRow + 2,
              weekStartCol + sIdx,
            )
            .merge();
      }

      // Total Column (last one)
      cell = sheet.getRangeByIndex(headerRow + 1, weekStartCol + 5);
      cell.setText('المجموع');
      cell.cellStyle = verticalGrayHeader;
      sheet
          .getRangeByIndex(
            headerRow + 1,
            weekStartCol + 5,
            headerRow + 2,
            weekStartCol + 5,
          )
          .merge();
    }
    currentRow += 3;

    // =========================================================================
    // MAX SCORES ROW
    // =========================================================================
    sheet.getRangeByIndex(currentRow, serialNumberCol).cellStyle = grayStyle;
    sheet.getRangeByIndex(currentRow, studentNameCol).setText('الدرجة');
    sheet.getRangeByIndex(currentRow, studentNameCol).cellStyle = grayStyle;

    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);

      for (var evalIdx = 0; evalIdx < maxScores.length; evalIdx++) {
        cell = sheet.getRangeByIndex(currentRow, weekStartCol + evalIdx);
        cell.setNumber(maxScores[evalIdx].toDouble());
        cell.cellStyle = (evalIdx % 2 == 0) ? whiteStyle : grayStyle;
      }

      // Total max score (30)
      cell = sheet.getRangeByIndex(currentRow, weekStartCol + 5);
      cell.setNumber(30);
      cell.cellStyle = grayStyle;
    }
    currentRow++;

    // =========================================================================
    // STUDENT DATA ROWS
    // =========================================================================
    for (var i = 0; i < 50; i++) {
      final studentData = i < printData.studentsData.length
          ? printData.studentsData[i]
          : null;

      cell = sheet.getRangeByIndex(currentRow, serialNumberCol);
      cell.setNumber((i + 1).toDouble());
      cell.cellStyle = whiteDataStyle;

      cell = sheet.getRangeByIndex(currentRow, studentNameCol);
      if (studentData != null) {
        cell.setText(studentData.student.name);
      }
      cell.cellStyle = studentNameStyle;

      for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
        final weekNum = weekNumbers[weekIdx];
        final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);

        // Individual scores
        for (var evalIdx = 0; evalIdx < evalIds.length; evalIdx++) {
          final evalId = evalIds[evalIdx];
          cell = sheet.getRangeByIndex(currentRow, weekStartCol + evalIdx);

          if (studentData != null) {
            final score = studentData.getScoreForWeek(weekNum, evalId);
            if (score > 0) cell.setNumber(score.toDouble());
          }
          cell.cellStyle = (evalIdx % 2 == 0) ? whiteDataStyle : grayDataStyle;
        }

        // Total at the end
        cell = sheet.getRangeByIndex(currentRow, weekStartCol + 5);
        if (studentData != null) {
          // Calculate local total for this template
          int weekTotal = 0;
          for (var evalId in evalIds) {
            weekTotal += studentData.getScoreForWeek(weekNum, evalId);
          }
          if (weekTotal > 0) cell.setNumber(weekTotal.toDouble());
        }
        cell.cellStyle = grayDataStyle;
        cell.cellStyle.bold = true;
      }
      currentRow++;
    }

    final int lastStudentRow = currentRow - 1;

    // =========================================================================
    // SIGNATURE SECTION
    // =========================================================================
    currentRow += 2;

    // Calculate center for better positioning
    final int midCol = (firstWeekStartCol + lastTableCol) ~/ 2;

    // Teacher: Closer to center
    final teacherRange = sheet.getRangeByIndex(
      currentRow,
      midCol - 4,
      currentRow,
      midCol - 1,
    );
    teacherRange.merge();
    teacherRange.setText('مدرس المادة: ........................');
    teacherRange.cellStyle.bold = true;
    teacherRange.cellStyle.fontSize = 18;
    teacherRange.cellStyle.hAlign = xlsio.HAlignType.center;

    // Principal: Closer to center
    final principalRange = sheet.getRangeByIndex(
      currentRow,
      midCol + 1,
      currentRow,
      midCol + 4,
    );
    principalRange.merge();
    principalRange.setText('مدير المدرسة: ........................');
    principalRange.cellStyle.bold = true;
    principalRange.cellStyle.fontSize = 18;
    principalRange.cellStyle.hAlign = xlsio.HAlignType.center;

    sheet.getRangeByIndex(currentRow, 1).rowHeight =
        40; // Increase height for clarity

    // =========================================================================
    // SET COLUMN WIDTHS & BORDERS
    // =========================================================================
    sheet.getRangeByIndex(1, 1).columnWidth = 2; // Margin column
    sheet.getRangeByIndex(1, serialNumberCol).columnWidth = 6;
    sheet.getRangeByIndex(1, studentNameCol).columnWidth = 40;
    for (var col = firstWeekStartCol; col <= lastTableCol; col++) {
      sheet.getRangeByIndex(1, col).columnWidth = 10;
    }

    // Name column border
    final nameColRange = sheet.getRangeByIndex(
      headerRow,
      studentNameCol,
      lastStudentRow,
      studentNameCol,
    );
    nameColRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thick;
    nameColRange.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thick;

    // Week borders
    for (var weekIdx = 0; weekIdx < weekNumbers.length; weekIdx++) {
      final weekStartCol = firstWeekStartCol + (weekIdx * weekBlockSize);
      final weekEndCol = weekStartCol + weekBlockSize - 1;

      final weekRange = sheet.getRangeByIndex(
        headerRow,
        weekEndCol, // The "Total" column
        lastStudentRow,
        weekEndCol,
      );
      weekRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thick;
    }

    final fullTableBottom = sheet.getRangeByIndex(
      lastStudentRow,
      serialNumberCol,
      lastStudentRow,
      lastTableCol,
    );
    fullTableBottom.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.thick;

    // Row heights
    sheet.getRangeByIndex(headerRow, 1).rowHeight = 30; // Week header
    sheet.getRangeByIndex(headerRow + 1, 1).rowHeight = 110; // Vertical text

    for (int i = headerRow + 3; i <= lastStudentRow; i++) {
      sheet.getRangeByIndex(i, 1).rowHeight = 30;
    }

    sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    sheet.pageSetup.paperSize = xlsio.ExcelPaperSize.paperA4;
    sheet.pageSetup.leftMargin = 0.25;
    sheet.pageSetup.rightMargin = 0.25;
    sheet.pageSetup.topMargin = 0.25;
    sheet.pageSetup.bottomMargin = 0.25;
    sheet.pageSetup.isFitToPage = true;
    sheet.pageSetup.fitToPagesWide = 1;
    sheet.pageSetup.fitToPagesTall = 1;

    final filePath = await _saveAndShareExcelFile(
      workbook.saveAsStream(),
      printData,
    );

    workbook.dispose();
    return filePath;
  }
}
