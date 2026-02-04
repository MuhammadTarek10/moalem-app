import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:moalem/core/constants/app_enums.dart' hide AttendanceStatus;
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

@injectable
class ExcelExportService {
  Future<String> exportToExcel(PrintDataEntity printData) async {
    // Use existing excel package for all groups
    // Check for attendance type first
    final ExcelTemplateConfig config;
    if (printData.printType == PrintType.attendance) {
      config = AttendanceConfig();
    } else {
      config = _configFor(printData.classEntity.evaluationGroup);
    }

    final excel = await config.loadTemplate();

    excel.setDefaultSheet(excel.tables.keys.first);

    // Standard single-sheet export for all configs
    final sheet = excel.tables.values.first;
    sheet.isRTL = true;
    config.fillMetadata(sheet, printData);
    config.fillStudents(sheet, printData);

    return config.save(excel, printData);
  }

  ExcelTemplateConfig _configFor(EvaluationGroup g) {
    switch (g) {
      case EvaluationGroup.prePrimary:
        return PrePrimaryConfig();
      case EvaluationGroup.primary:
        return Primary36Config();
      case EvaluationGroup.secondary:
        return PreparatoryConfig();
      case EvaluationGroup.high:
        return SecondaryMonthlyConfig();
    }
  }
}

// =======================================================
// Core Template Config
// =======================================================

abstract class ExcelTemplateConfig {
  String get templateName;

  Future<Excel> loadTemplate() async {
    final ByteData data = await rootBundle.load('assets/files/$templateName');
    final bytes = data.buffer.asUint8List();
    try {
      return Excel.decodeBytes(bytes);
    } catch (_) {
      return Excel.decodeBytes(await _patchNumFmtId(bytes));
    }
  }

  Future<Uint8List> _patchNumFmtId(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final newArchive = Archive();
    for (final file in archive.files) {
      if (file.name == 'xl/styles.xml') {
        String content = String.fromCharCodes(file.content as List<int>);
        content = content.replaceAllMapped(
          RegExp(r'<numFmt\s+numFmtId="(\d+)"[^>]*/?>'),
          (m) {
            final id = int.parse(m.group(1)!);
            return id < 164 ? '' : m.group(0)!;
          },
        );
        newArchive.addFile(
          ArchiveFile(file.name, content.length, content.codeUnits),
        );
      } else {
        newArchive.addFile(file);
      }
    }
    return Uint8List.fromList(ZipEncoder().encode(newArchive)!);
  }

  void fillMetadata(Sheet sheet, PrintDataEntity data);
  void fillStudents(Sheet sheet, PrintDataEntity data);

  Future<String> save(Excel excel, PrintDataEntity data) async {
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    String safe(String v) => v.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    final fileName =
        '${safe(data.classEntity.name)}_'
        '${data.classEntity.evaluationGroup.name}_'
        '$ts.xlsx';

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to save excel file');
    }
    final f = File(path);
    await f.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(path)]);
    return path;
  }

  // helpers
  int min3(int a, int b, int c) => [a, b, c].reduce((x, y) => x < y ? x : y);
}

// =======================================================
// 1) أولى / تانية ابتدائي (PrePrimary)
// =======================================================

class PrePrimaryConfig extends ExcelTemplateConfig {
  @override
  String get templateName => 'كشف فارغ اعمال السنة اولى وتانية ابتدائى.xlsx';

  // metadata (حسب التمبلت الفعلي)
  final Map<String, CellIndex> meta = {
    'governorate': CellIndex.indexByColumnRow(
      columnIndex: 2,
      rowIndex: 0,
    ), // C1
    'administration': CellIndex.indexByColumnRow(
      columnIndex: 2,
      rowIndex: 1,
    ), // C2
    'school': CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2), // C3
    'class': CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 3), // M4
    'subject': CellIndex.indexByColumnRow(columnIndex: 26, rowIndex: 3), // AA4
  };

  // Student data starts at row 8 (0-indexed) = Row 9 in Excel
  final int studentStartRow = 8;
  final int serialColumn = 1; // Column B
  final int nameColumn = 2; // Column C

  // Each week has 8 columns: 7 evaluations + 1 total
  // Week structure starts at column 3 (D)
  final int firstWeekStartCol = 3;
  final int columnsPerWeek = 8;

  // Evaluation IDs matching template order
  final List<String> evalIds = [
    'pre_classwork', // كراس أداء صفى
    'pre_homework', // كراس الواجب
    'pre_activity', // كراس النشاط
    'pre_weekly', // تقييم أسبوعى
    'pre_oral', // مهام شفهية
    'pre_skill', // مهام مهارية
    'pre_attendance', // حضور ومواظبة
  ];

  @override
  Future<Excel> loadTemplate() async {
    // Just load the template as-is (single sheet with 5 weeks)
    return await super.loadTemplate();
  }

  @override
  void fillMetadata(Sheet sheet, PrintDataEntity d) {
    // Read existing template text and append data
    // C1: "مديرية التربية والتعليم …..................................."
    final govCell = sheet.cell(meta['governorate']!);
    final govTemplate = govCell.value?.toString() ?? 'مديرية التربية والتعليم ';
    // Replace the dots with the actual governorate name
    final govText = govTemplate.replaceAll(RegExp(r'[\.…]+'), d.governorate);
    sheet.updateCell(meta['governorate']!, TextCellValue(govText));

    // C2: "ادارة  ….........................................................."
    final adminCell = sheet.cell(meta['administration']!);
    final adminTemplate = adminCell.value?.toString() ?? 'ادارة  ';
    final adminText = adminTemplate.replaceAll(
      RegExp(r'[\.…]+'),
      d.administration,
    );
    sheet.updateCell(meta['administration']!, TextCellValue(adminText));

    // C3: "مدرسة / ….........................................................."
    final schoolCell = sheet.cell(meta['school']!);
    final schoolTemplate = schoolCell.value?.toString() ?? 'مدرسة / ';
    final schoolText = schoolTemplate.replaceAll(
      RegExp(r'[\.…]+'),
      d.classEntity.school,
    );
    sheet.updateCell(meta['school']!, TextCellValue(schoolText));

    // M4: "سجل رصد درجات فصل            /"
    final classCell = sheet.cell(meta['class']!);
    final classTemplate =
        classCell.value?.toString() ?? 'سجل رصد درجات فصل            /';
    // Replace spaces before / with the class info (e.g., "1/3")
    final classInfo = '${d.classEntity.grade}/${d.classEntity.name}';
    final classText = classTemplate.replaceAll(
      RegExp(r'\s+/'),
      '   $classInfo',
    );
    sheet.updateCell(meta['class']!, TextCellValue(classText));

    // AA4: "مادة : …...................."
    final subjectCell = sheet.cell(meta['subject']!);
    final subjectTemplate = subjectCell.value?.toString() ?? 'مادة : ';
    final subjectText = subjectTemplate.replaceAll(
      RegExp(r'[\.…]+'),
      d.classEntity.subject,
    );
    sheet.updateCell(meta['subject']!, TextCellValue(subjectText));

    // Set column width for subject cell (column AA = 26) to ensure full text is visible
    sheet.setColumnWidth(26, 30); // Width in characters
  }

  @override
  void fillStudents(Sheet sheet, PrintDataEntity data) {
    // Determine which weeks to fill based on weekGroup
    final weekNumbers =
        data.weekNumbers; // This already handles weekGroup logic
    final isLastPage = data.weekGroup == 4; // Page 4 includes semester average

    for (int i = 0; i < data.studentsData.length; i++) {
      final student = data.studentsData[i];
      // Students start at row 8 (0-indexed) which is Row 9 in Excel
      final row = studentStartRow + i;

      // Serial number in column B (serialColumn = 1)
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: serialColumn, rowIndex: row),
        IntCellValue(i + 1),
      );

      // Student name in column C (nameColumn = 2)
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: nameColumn, rowIndex: row),
        TextCellValue(student.student.name),
      );

      // Fill scores for each week in the selected group
      for (int w = 0; w < weekNumbers.length && w < 5; w++) {
        final weekNo = weekNumbers[w];
        final weekStartCol = firstWeekStartCol + (w * columnsPerWeek);

        // Fill each evaluation type for this week
        for (int e = 0; e < evalIds.length; e++) {
          final score = student.getScoreForWeek(weekNo, evalIds[e]);
          if (score > 0) {
            sheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: weekStartCol + e,
                rowIndex: row,
              ),
              IntCellValue(score),
            );
          }
        }

        // Fill total for this week (8th column in the week block)
        final total = student.getTotalForWeek(weekNo);
        if (total > 0) {
          sheet.updateCell(
            CellIndex.indexByColumnRow(
              columnIndex: weekStartCol + 7, // Total column
              rowIndex: row,
            ),
            IntCellValue(total),
          );
        }
      }

      // If this is page 4 (weeks 16-18), add semester 2 average
      if (isLastPage) {
        _addSemesterAverage(sheet, student, row, weekNumbers.length);
      }
    }
  }

  void _addSemesterAverage(
    Sheet sheet,
    StudentPrintData student,
    int row,
    int weekCount,
  ) {
    // Calculate semester 2 average (weeks 1-18)
    int totalScore = 0;
    int weeksCounted = 0;

    for (int w = 1; w <= 18; w++) {
      final weekTotal = student.getTotalForWeek(w);
      if (weekTotal > 0) {
        totalScore += weekTotal;
        weeksCounted++;
      }
    }

    if (weeksCounted > 0) {
      final average = (totalScore / weeksCounted).round();

      // Place average in column after the last week
      // Last week ends at: firstWeekStartCol + (weekCount * columnsPerWeek) - 1
      // Average column: firstWeekStartCol + (weekCount * columnsPerWeek)
      final averageCol = firstWeekStartCol + (weekCount * columnsPerWeek);

      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: averageCol, rowIndex: row),
        IntCellValue(average),
      );
    }
  }
}

// =======================================================
// 2) 3–6 ابتدائي (Primary)
// =======================================================

class Primary36Config extends ExcelTemplateConfig {
  @override
  String get templateName => 'كشف فارغ اعمال السنة من 3ل6 ابتدائى.xlsx';

  /* =====================================================
   * 1) Metadata cells (من التمبلت حرفيًا)
   * ===================================================== */
  final Map<String, CellIndex> metaCells = {
    'governorate': CellIndex.indexByString('C1'),
    'administration': CellIndex.indexByString('C2'),
    'school': CellIndex.indexByString('C3'),
    'class': CellIndex.indexByString('M4'),
    'subject': CellIndex.indexByString('X4'),
  };

  /* =====================================================
   * 2) Students table basics
   * ===================================================== */
  final int studentStartRow = 8; // Row 9 in Excel (0-indexed)
  final int serialColumn = 1; // B
  final int nameColumn = 2; // C

  /* =====================================================
   * 3) 18 Weeks – Based on template analysis
   * Template: First week at D5 (col 3), 6 columns per week
   * Evaluation order in each week block (LTR):
   * [0] أداء الطالب (Performance)
   * [1] الواجب (Homework)
   * [2] النشاط (Activity)  
   * [3] أسبوعي (Weekly)
   * [4] مهاري ومواظبة (Attendance)
   * [5] المجموع (Total)
   * ===================================================== */

  // First week starts at column 3 (D), each week is 6 columns
  final int firstWeekCol = 3;
  final int colsPerWeek = 6;

  // Evaluation IDs in template order
  final List<String> evalOrder = [
    'primary_performance', // أداء الطالب
    'primary_homework', // الواجب
    'primary_activity', // النشاط
    'primary_weekly', // أسبوعي
    'primary_attendance', // مهاري ومواظبة
  ];

  /* =====================================================
   * 4) Fill metadata
   * ===================================================== */
  @override
  void fillMetadata(Sheet sheet, PrintDataEntity data) {
    sheet.updateCell(
      metaCells['governorate']!,
      TextCellValue('مديرية التربية والتعليم ${data.governorate}'),
    );
    sheet.updateCell(
      metaCells['administration']!,
      TextCellValue('إدارة ${data.administration}'),
    );
    sheet.updateCell(
      metaCells['school']!,
      TextCellValue('مدرسة ${data.classEntity.school}'),
    );

    // Class/Title
    // final classInfo = '${data.classEntity.grade}/${data.classEntity.name}';
    final classText = 'سجل رصد درجات فصل    ${data.classEntity.name}';
    sheet.updateCell(metaCells['class']!, TextCellValue(classText));

    sheet.updateCell(
      metaCells['subject']!,
      TextCellValue('مادة : ${data.classEntity.subject}'),
    );

    // Clear duplicate/placeholder cells from the template
    // "Subject" placeholder was at T4
    sheet.updateCell(CellIndex.indexByString('T4'), TextCellValue(''));
    // "Class Title" placeholder was likely around I4/J4
    sheet.updateCell(CellIndex.indexByString('I4'), TextCellValue(''));

    // Increase height for row 4 (index 3) to show full vertical subject name
    sheet.setRowHeight(3, 120.0);

    // Increase height for row 8 (index 7) - Evaluation Headers
    // To ensure vertical text like "Evaluation Name" is not cut off
    sheet.setRowHeight(7, 180.0);
  }

  /* =====================================================
   * 5) Fill students & scores
   * ===================================================== */
  @override
  void fillStudents(Sheet sheet, PrintDataEntity data) {
    final weekNumbers = data.weekNumbers;

    // Define a centered style for all student data cells
    final centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontFamily: getFontFamily(FontFamily.Arial),
    );

    for (int i = 0; i < data.studentsData.length; i++) {
      final student = data.studentsData[i];
      // Stride is 2 because of merged cells
      final row = studentStartRow + (i * 2);

      // Serial number
      var cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: serialColumn, rowIndex: row),
      );
      cell.value = IntCellValue(i + 1);
      cell.cellStyle = centerStyle;

      // Student name
      cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: nameColumn, rowIndex: row),
      );
      cell.value = TextCellValue(student.student.name);
      cell.cellStyle = centerStyle;

      // Fill scores for each week
      for (int w = 0; w < weekNumbers.length; w++) {
        final weekNo = weekNumbers[w];
        final weekStartCol = firstWeekCol + (w * colsPerWeek);

        // Fill each evaluation in order
        for (int e = 0; e < evalOrder.length; e++) {
          final score = student.getScoreForWeek(weekNo, evalOrder[e]);
          if (score > 0) {
            var cell = sheet.cell(
              CellIndex.indexByColumnRow(
                columnIndex: weekStartCol + e,
                rowIndex: row,
              ),
            );
            cell.value = IntCellValue(score);
            cell.cellStyle = centerStyle;
          }
        }

        // Fill total (last column in the week block)
        final total = student.getTotalForWeek(weekNo);
        if (total > 0) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: weekStartCol + evalOrder.length,
              rowIndex: row,
            ),
          );
          cell.value = IntCellValue(total);
          cell.cellStyle = centerStyle;
        }
      }
    }
  }
}

/* =====================================================
 * Helper class
 * ===================================================== */
class WeekBlock {
  final int homework;
  final int activity;
  final int weekly;
  final int performance;
  final int attendance;
  final int total;

  const WeekBlock(
    this.homework,
    this.activity,
    this.weekly,
    this.performance,
    this.attendance,
    this.total,
  );
}
/* ========================= */

/* =========================
 * Helper
 * ========================= */
// 3) إعدادي (Preparatory)
// =======================================================

class PreparatoryConfig extends ExcelTemplateConfig {
  @override
  String get templateName => 'كشف فارغ اعمال السنة اعدادى.xlsx';

  // Metadata positions based on template analysis:
  // C1 = Governorate, C2 = Administration, C3 = School, L4 = Subject, D4 = Title
  final Map<String, CellIndex> meta = {
    'governorate': CellIndex.indexByColumnRow(
      columnIndex: 2,
      rowIndex: 0,
    ), // C1
    'administration': CellIndex.indexByColumnRow(
      columnIndex: 2,
      rowIndex: 1,
    ), // C2
    'school': CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2), // C3
    'subject': CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 3), // L4
  };

  // Student data starts at row 8 (0-indexed: 7) based on analysis
  final int studentStartRow = 7;
  final int serialColumn = 1; // B
  final int nameColumn = 2; // C

  // Week structure: 5 weeks visible at a time, 4 cols per week
  final int firstWeekCol = 3; // D
  final int colsPerWeek = 4;

  final List<String> evalIds = [
    'prep_hw',
    'prep_activity',
    'prep_weekly',
    'prep_attendance',
  ];

  @override
  void fillMetadata(Sheet sheet, PrintDataEntity d) {
    sheet.updateCell(meta['governorate']!, TextCellValue(d.governorate));
    sheet.updateCell(meta['administration']!, TextCellValue(d.administration));
    sheet.updateCell(meta['school']!, TextCellValue(d.classEntity.school));
    sheet.updateCell(meta['subject']!, TextCellValue(d.classEntity.subject));
  }

  @override
  void fillStudents(Sheet sheet, PrintDataEntity d) {
    final weekNumbers = d.weekNumbers;

    for (int i = 0; i < d.studentsData.length; i++) {
      final student = d.studentsData[i];
      final row = studentStartRow + i;

      // Serial number
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: serialColumn, rowIndex: row),
        IntCellValue(i + 1),
      );

      // Student name
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: nameColumn, rowIndex: row),
        TextCellValue(student.student.name),
      );

      // Fill scores for each week (up to 5 weeks visible in template)
      for (int w = 0; w < weekNumbers.length && w < 5; w++) {
        final weekNo = weekNumbers[w];
        final weekStartCol = firstWeekCol + (w * colsPerWeek);

        // Fill each evaluation type for this week
        for (int e = 0; e < evalIds.length; e++) {
          final score = student.getScoreForWeek(weekNo, evalIds[e]);
          if (score > 0) {
            sheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: weekStartCol + e,
                rowIndex: row,
              ),
              IntCellValue(score),
            );
          }
        }
      }
    }
  }
}

// =======================================================
// 4) ثانوي (نظام شهور) – لا نكسر الفورمولات
// =======================================================

class SecondaryMonthlyConfig extends ExcelTemplateConfig {
  @override
  String get templateName => 'كشف فارغ اعمال السنة ثانوى نظام شهور.xlsx';

  // Metadata positions
  final Map<String, CellIndex> meta = {
    'school': CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2), // A3
    'subject': CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: 0), // W1
  };

  // Student data starts at row 9 (0-indexed: 8)
  final int studentStartRow = 8;
  final int serialColumn = 0; // A - م
  final int nameColumn = 1; // B - الاسم

  // Template structure per month (RTL - right to left):
  // Each month has 8 columns:
  // Col offset 0: سلوك و مواظبة (10)
  // Col offset 1: كشكول الحصة والواجب (15)
  // Col offset 2: الأسبوع الرابع (15)
  // Col offset 3: الأسبوع الثالث (15)
  // Col offset 4: الأسبوع الثاني (15)
  // Col offset 5: الأسبوع الأول (15)
  // Col offset 6: متوسط التقييمات (40) - calculated
  // Col offset 7: المجموع - calculated

  // Month start columns (0-indexed) - from template analysis
  // February (فبراير) is rightmost, then March, then April
  // Based on template: columns go RTL
  final Map<int, int> monthStartColumns = {
    1: 2, // Month 1 (فبراير) starts at column C (index 2)
    2: 10, // Month 2 (مارس) starts at column K (index 10)
    3: 18, // Month 3 (أبريل) starts at column S (index 18)
  };

  final int columnsPerMonth = 8;
  final int weeksPerMonth = 4;

  @override
  void fillMetadata(Sheet sheet, PrintDataEntity d) {
    // 1. Right side (A1, A2, A3)
    // Governorate
    final govCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    final govTemplate = govCell.value?.toString() ?? 'محافظة ';
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      TextCellValue(govTemplate.replaceAll(RegExp(r'[\.…]+'), d.governorate)),
    );

    // Administration
    final adminCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
    );
    final adminTemplate = adminCell.value?.toString() ?? 'إدارة ';
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      TextCellValue(
        adminTemplate.replaceAll(RegExp(r'[\.…]+'), d.administration),
      ),
    );

    // School
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      TextCellValue(d.classEntity.school),
    );

    // 2. Left side (W1, W2, W3 -> Col 22)
    // Subject
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: 0),
      TextCellValue('المادة / ${d.classEntity.subject}'),
    );

    // Grade
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: 1),
      TextCellValue('الصف / ${d.classEntity.grade}'),
    );

    // Class
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: 2),
      TextCellValue('الفصل / ${d.classEntity.name}'),
    );
  }

  @override
  void fillStudents(Sheet sheet, PrintDataEntity d) {
    // Student indices
    final int colTotal3Months = 26; // AA
    final int colAvg3Months = 27; // AB
    final int colExam1 = 28; // AC
    final int colExam2 = 29; // AD
    final int colTotalYear = 30; // AE

    // Map evaluation IDs by name for dynamic lookup
    final evalMap = {for (var e in d.evaluations!) e.name: e.id};
    final weeklyId = evalMap['weekly_review'] ?? 'weekly_review';
    final behId =
        evalMap['attendance_and_diligence'] ?? 'attendance_and_diligence';
    final bookId = evalMap['homework_book'] ?? 'homework_book';
    final ex1Id = evalMap['first_month_exam'] ?? 'first_month_exam';
    final ex2Id = evalMap['second_month_exam'] ?? 'second_month_exam';

    for (int i = 0; i < d.studentsData.length; i++) {
      final student = d.studentsData[i];
      final row = studentStartRow + i;

      // Serial
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: serialColumn, rowIndex: row),
        IntCellValue(i + 1),
      );

      // Name
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: nameColumn, rowIndex: row),
        TextCellValue(student.student.name),
      );

      int sumMonthlyTotals = 0;

      // Fill Month Data (1=Feb, 2=Mar, 3=Apr)
      for (int m = 1; m <= 3; m++) {
        final monthTotal = _fillMonthData(
          sheet,
          student,
          row,
          m,
          weeklyId: weeklyId,
          behId: behId,
          bookId: bookId,
        );
        sumMonthlyTotals += monthTotal;
      }

      // Exam Scores
      int exam1 = 0;
      int exam2 = 0;

      if (student.weeklyScores != null) {
        for (var weekScores in student.weeklyScores!.values) {
          if (weekScores.containsKey(ex1Id)) exam1 = weekScores[ex1Id]!;
          if (weekScores.containsKey(ex2Id)) exam2 = weekScores[ex2Id]!;
        }
      }

      // Aggregates
      if (sumMonthlyTotals > 0) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(
            columnIndex: colTotal3Months,
            rowIndex: row,
          ),
          IntCellValue(sumMonthlyTotals),
        );
      }
      final avg3Months = (sumMonthlyTotals / 3).round();
      if (avg3Months > 0) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: colAvg3Months, rowIndex: row),
          IntCellValue(avg3Months),
        );
      }
      if (exam1 > 0) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: colExam1, rowIndex: row),
          IntCellValue(exam1),
        );
      }
      if (exam2 > 0) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: colExam2, rowIndex: row),
          IntCellValue(exam2),
        );
      }
      final totalYear = avg3Months + exam1 + exam2;
      if (totalYear > 0) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: colTotalYear, rowIndex: row),
          IntCellValue(totalYear),
        );
      }
    }
  }

  int _fillMonthData(
    Sheet sheet,
    StudentPrintData student,
    int row,
    int month, {
    required String weeklyId,
    required String behId,
    required String bookId,
  }) {
    if (!monthStartColumns.containsKey(month)) return 0;
    final startCol = monthStartColumns[month]!;

    // Base week for this month
    final baseWeek = (month - 1) * 4 + 1;

    int monthWeeklySum = 0;
    int monthBehSum = 0;
    int monthBookSum = 0;
    int weeksCountRow = 0;

    for (int w = 0; w < 4; w++) {
      final weekNo = baseWeek + w;
      final wkScore = student.getScoreForWeek(weekNo, weeklyId);
      final behScore = student.getScoreForWeek(weekNo, behId);
      final bookScore = student.getScoreForWeek(weekNo, bookId);

      if (wkScore > 0) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(
            columnIndex: startCol + 2 + w,
            rowIndex: row,
          ),
          IntCellValue(wkScore),
        );
        monthWeeklySum += wkScore;
        weeksCountRow++;
      }
      monthBehSum += behScore;
      monthBookSum += bookScore;
    }

    final avgWeekly = weeksCountRow > 0
        ? (monthWeeklySum / weeksCountRow).round()
        : 0;
    final avgBeh = (monthBehSum / 4).round();
    final avgBook = (monthBookSum / 4).round();

    if (avgBeh > 0) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: startCol,
          rowIndex: row,
        ), // S/B is Col 0 relative
        IntCellValue(avgBeh),
      );
    }
    if (avgBook > 0) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: startCol + 1,
          rowIndex: row,
        ), // H/W is Col 1 relative
        IntCellValue(avgBook),
      );
    }
    if (avgWeekly > 0)
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: startCol + 6, rowIndex: row),
        IntCellValue(avgWeekly),
      );

    final total = avgBeh + avgBook + avgWeekly;
    if (total > 0)
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: startCol + 7, rowIndex: row),
        IntCellValue(total),
      );

    return total;
  }
}

// =======================================================
// 5) Attendance Config (Unified for all stages)
// =======================================================

class AttendanceConfig extends ExcelTemplateConfig {
  @override
  String get templateName => 'attendance-evaluations.xlsx';

  // Metadata positions (Standard Layout)
  final Map<String, CellIndex> meta = {
    'governorate': CellIndex.indexByColumnRow(
      columnIndex: 2,
      rowIndex: 0,
    ), // C1
    'administration': CellIndex.indexByColumnRow(
      columnIndex: 2,
      rowIndex: 1,
    ), // C2
    'school': CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2), // C3
    'class': CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 3), // L4
    'subject': CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3), // D4
  };

  final int studentStartRow = 8;
  final int serialColumn = 1; // B
  final int nameColumn = 2; // C

  // Attendance columns
  final int firstWeekCol = 3;
  final int daysPerWeek = 6; // Sat, Sun, Mon, Tue, Wed, Thu

  @override
  void fillMetadata(Sheet sheet, PrintDataEntity d) {
    // Fill basic metadata
    final govCell = sheet.cell(meta['governorate']!);
    final govTemplate = govCell.value?.toString() ?? 'مديرية التربية والتعليم ';
    sheet.updateCell(
      meta['governorate']!,
      TextCellValue(govTemplate.replaceAll(RegExp(r'[\.…]+'), d.governorate)),
    );

    final adminCell = sheet.cell(meta['administration']!);
    final adminTemplate = adminCell.value?.toString() ?? 'ادارة  ';
    sheet.updateCell(
      meta['administration']!,
      TextCellValue(
        adminTemplate.replaceAll(RegExp(r'[\.…]+'), d.administration),
      ),
    );

    final schoolCell = sheet.cell(meta['school']!);
    final schoolTemplate = schoolCell.value?.toString() ?? 'مدرسة / ';
    sheet.updateCell(
      meta['school']!,
      TextCellValue(
        schoolTemplate.replaceAll(RegExp(r'[\.…]+'), d.classEntity.school),
      ),
    );

    // For attendance, we usually just show class name and grade
    if (meta.containsKey('class')) {
      sheet.updateCell(
        meta['class']!,
        TextCellValue('${d.classEntity.grade} / ${d.classEntity.name}'),
      );
    }
  }

  @override
  void fillStudents(Sheet sheet, PrintDataEntity data) {
    final weekNumbers = data.weekNumbers;

    for (int i = 0; i < data.studentsData.length; i++) {
      final student = data.studentsData[i];
      final row = studentStartRow + i;

      // Serial
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: serialColumn, rowIndex: row),
        IntCellValue(i + 1),
      );

      // Name
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: nameColumn, rowIndex: row),
        TextCellValue(student.student.name),
      );

      // Fill Attendance Days
      for (int w = 0; w < weekNumbers.length && w < 5; w++) {
        final weekNo = weekNumbers[w];
        final weekStartCol = firstWeekCol + (w * daysPerWeek);
        final weekStartDate = data.weekStartDates?[weekNo];

        if (weekStartDate != null) {
          // Get days: Sat, Sun, Mon, Tue, Wed, Thu
          for (int d = 0; d < 6; d++) {
            // Calculate date for this day index (0=Sat, 1=Sun, ..., 5=Thu)
            final date = weekStartDate.add(Duration(days: d));

            // Check attendance status
            final status = student.getAttendanceForWeekDate(weekNo, date);
            if (status != null) {
              String mark = '';
              if (status == AttendanceStatus.absent) {
                mark = 'غ';
              } else if (status == AttendanceStatus.excused) {
                mark = 'ع';
              }

              if (mark.isNotEmpty) {
                sheet.updateCell(
                  CellIndex.indexByColumnRow(
                    columnIndex: weekStartCol + d,
                    rowIndex: row,
                  ),
                  TextCellValue(mark),
                );
              }
            }
          }
        }
      }
    }
  }
}
