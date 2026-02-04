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
    final defaultSheetName = excel.tables.keys.first;

    // Delegate chunking strategy to the config
    final weekChunks = config.getWeekChunks(printData);

    if (weekChunks.isEmpty) {
      // Fallback if no weeks
      final sheet = excel.tables[defaultSheetName]!;
      sheet.isRTL = true;
      config.fillMetadata(sheet, printData);
    } else {
      // 1. Prepare Sheets (Copy FIRST to avoid copying filled data)
      final List<String> sheetNames = [];
      sheetNames.add(defaultSheetName); // Sheet 1 is the default

      for (int i = 1; i < weekChunks.length; i++) {
        final newName = '${defaultSheetName}_${i + 1}';
        excel.copy(defaultSheetName, newName);
        sheetNames.add(newName);
      }

      // 2. Fill Sheets
      for (int i = 0; i < weekChunks.length; i++) {
        final currentWeeks = weekChunks[i];
        final sheetName = sheetNames[i];
        final sheet = excel.tables[sheetName]!;
        sheet.isRTL = true;

        config.fillMetadata(sheet, printData);
        config.fillWeekHeaders(
          sheet,
          currentWeeks,
          printData.weekStartDates ?? {},
        );
        config.fillStudents(sheet, printData, weeksOverride: currentWeeks);
      }
    }

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

  // Default chunking logic (5 weeks)
  List<List<int>> getWeekChunks(PrintDataEntity data) {
    final allWeeks = data.weekNumbers;
    // Calculate 5-week chunks
    return List.generate(
      (allWeeks.length / 5).ceil(),
      (i) => allWeeks.sublist(
        i * 5,
        (i * 5 + 5) > allWeeks.length ? allWeeks.length : i * 5 + 5,
      ),
    );
  }

  // Default no-op for headers
  void fillWeekHeaders(
    Sheet sheet,
    List<int> weeks,
    Map<int, DateTime> weekStartDates,
  ) {}

  void fillStudents(
    Sheet sheet,
    PrintDataEntity data, {
    List<int>? weeksOverride,
  });

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

  // Student data starts at row 8 (0-indexed) = Row 9 in Excel (C9 for first student)
  final int studentStartRow = 8;
  final int serialColumn = 1; // Column B - NOT USED, serial comes from template
  final int nameColumn = 2; // Column C

  // Each week has 8 columns: 7 evaluations + 1 total
  // Week structure starts at column 3 (D)
  final int firstWeekStartCol = 3;
  final int columnsPerWeek = 8;

  // Evaluation IDs matching App Values (core/constants/app_values.dart)
  // Reordered: كراس الواجب first as requested
  final List<String> evalIds = [
    'homework_book', // كراس الواجب (FIRST)
    'classroom_performance', // كراس أداء صفى
    'activity_book', // كراس النشاط
    'weekly_review', // تقييم أسبوعى
    'oral_tasks', // مهام شفهية
    'skill_tasks', // مهام مهارية
    'attendance_and_diligence', // حضور ومواظبة
  ];

  // Arabic Labels for Headers (كراس الواجب first)
  final List<String> evalLabels = [
    'كراس الواجب',
    'كراس اداء صفى',
    'كراس النشاط',
    'تقييم أسبوعى',
    'مهام شفهية',
    'مهام مهارية',
    'حضور و مواظبة',
  ];

  // Max Scores
  final List<int> maxScores = [
    20, // classroom_performance
    20, // homework_book
    20, // activity_book
    20, // weekly_review
    10, // oral_tasks
    5, // skill_tasks
    5, // attendance_and_diligence
  ];
  final int totalMaxScore = 100;

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
        classCell.value?.toString() ?? 'سجل رصد درجات فصل       /';
    // Replace spaces before / with the class info (e.g., "1/3")
    final classInfo = d.classEntity.name;
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
  void fillWeekHeaders(
    Sheet sheet,
    List<int> weeks,
    Map<int, DateTime> weekStartDates,
  ) {
    // Strategy: Preserve ALL template formatting
    // Only update cell VALUES for week numbers and dates
    // Template already has all styles, borders, colors, fonts

    // Arabic ordinal names for weeks
    final weekOrdinals = [
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
    ];

    // Update week titles only (Row 5, index 4)
    // Template already has merged cells and styling
    for (int w = 0; w < weeks.length && w < 5; w++) {
      final weekNo = weeks[w];
      final colIndex = firstWeekStartCol + (w * columnsPerWeek);

      // Build week title with ordinal name and date
      final weekOrdinal = weekNo <= weekOrdinals.length
          ? weekOrdinals[weekNo - 1]
          : weekNo.toString();
      final date = weekStartDates[weekNo];
      final dateStr = date != null ? DateFormat('d/M').format(date) : '';
      final weekTitle = 'الأسبوع $weekOrdinal  $dateStr';

      // Update ONLY the value - preserve template style
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 4),
        TextCellValue(weekTitle),
      );
    }

    // Apply vertical rotation to ALL evaluation headers in weeks (Row 7, index 6)
    // Get template style from first evaluation cell
    final templateEvalCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: firstWeekStartCol, rowIndex: 6),
    );
    var weekEvalStyle = templateEvalCell.cellStyle;

    // Apply vertical rotation to the style
    if (weekEvalStyle != null) {
      weekEvalStyle = weekEvalStyle.copyWith(
        rotationVal: 90,
        horizontalAlignVal: HorizontalAlign.Center,
        verticalAlignVal: VerticalAlign.Center,
        boldVal: true,
        fontSizeVal: 12, // Bigger font
      );

      // Apply to all evaluation headers in all weeks
      for (int w = 0; w < weeks.length && w < 5; w++) {
        final weekStartCol = firstWeekStartCol + (w * columnsPerWeek);
        // 7 evaluation columns per week (excluding total)
        for (int col = 0; col < 7; col++) {
          final cellIndex = CellIndex.indexByColumnRow(
            columnIndex: weekStartCol + col,
            rowIndex: 6,
          );
          // Force apply style to ensure all columns (including last 3) are vertical
          sheet.cell(cellIndex).cellStyle = weekEvalStyle;
        }
      }
    }

    // Clear unused week columns if less than 5 weeks
    // This prevents template's week 4 and 5 from showing on page 4
    if (weeks.length < 5) {
      for (int w = weeks.length; w < 5; w++) {
        final colIndex = firstWeekStartCol + (w * columnsPerWeek);

        // Clear week title (Row 5)
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 4),
          TextCellValue(''),
        );

        // Clear all 8 columns for this unused week (rows 5-7 and data rows)
        for (int col = 0; col < columnsPerWeek; col++) {
          // Clear header rows (5, 6, 7)
          for (int row = 4; row <= 6; row++) {
            sheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex + col,
                rowIndex: row,
              ),
              TextCellValue(''),
            );
          }
        }
      }
    }

    // If this is page 4 (weeks 16-18), add semester average headers
    final isPage4 = weeks.contains(18);
    if (isPage4) {
      // Semester average section starts after the last week (3 weeks on page 4)
      final avgStartCol = firstWeekStartCol + (weeks.length * columnsPerWeek);

      // Copy the style from an existing week header cell to use for semester average
      final templateWeekCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: firstWeekStartCol, rowIndex: 4),
      );
      final weekHeaderStyle = templateWeekCell.cellStyle;

      // Semester average header in Row 5 (index 4) - merged across 7 columns
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: avgStartCol, rowIndex: 4),
        CellIndex.indexByColumnRow(columnIndex: avgStartCol + 6, rowIndex: 4),
        customValue: TextCellValue('متوسط الفصل الدراسي الثاني'),
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: avgStartCol, rowIndex: 4),
        TextCellValue('متوسط الفصل الدراسي الثاني'),
      );
      // Apply copied style from template
      if (weekHeaderStyle != null) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: avgStartCol,
                    rowIndex: 4,
                  ),
                )
                .cellStyle =
            weekHeaderStyle;
      }

      // Copy evaluation header style and ensure vertical rotation
      final templateEvalCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: firstWeekStartCol, rowIndex: 6),
      );
      var evalHeaderStyle = templateEvalCell.cellStyle;

      // Ensure vertical rotation (90 degrees) for subject headers
      if (evalHeaderStyle != null) {
        evalHeaderStyle = evalHeaderStyle.copyWith(
          rotationVal: 90,
          horizontalAlignVal: HorizontalAlign.Center,
          verticalAlignVal: VerticalAlign.Center,
          boldVal: true,
          fontSizeVal: 12,
        );
      }

      // Evaluation headers in Row 7 (index 6) - 7 subjects only
      // We skip Row 6 (Index 5) to keep the template's "جوانب التقييم" header
      for (int i = 0; i < evalLabels.length; i++) {
        final cellIndex = CellIndex.indexByColumnRow(
          columnIndex: avgStartCol + i,
          rowIndex: 6, // Row 7
        );
        sheet.updateCell(cellIndex, TextCellValue(evalLabels[i]));
        // Apply style with vertical rotation
        if (evalHeaderStyle != null) {
          sheet.cell(cellIndex).cellStyle = evalHeaderStyle;
        }
      }

      // Add "Total" header for Semester Average (8th column)
      final totalHeaderIndex = CellIndex.indexByColumnRow(
        columnIndex: avgStartCol + 7,
        rowIndex: 6, // Row 7
      );
      sheet.updateCell(totalHeaderIndex, TextCellValue('المجموع'));
      if (evalHeaderStyle != null) {
        sheet.cell(totalHeaderIndex).cellStyle = evalHeaderStyle;
      }
    }

    // Clear extra cells AJ5:AQ58 (columns 35-42, rows 4-58)
    // AJ = column 35 (26 + 9 = 35)
    // This clears the "Useless 20" and other residuals
    if (weeks.length < 5) {
      for (int row = 4; row < 58; row++) {
        for (int col = 35; col <= 42; col++) {
          sheet.updateCell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
            TextCellValue(''),
          );
        }
      }
    }
  }

  @override
  void fillStudents(
    Sheet sheet,
    PrintDataEntity data, {
    List<int>? weeksOverride,
  }) {
    // Determine which weeks to fill based on weekGroup
    final weekNumbers = weeksOverride ?? data.weekNumbers;
    final isLastPage = weekNumbers.contains(
      18,
    ); // Page 4 includes semester average

    for (int i = 0; i < data.studentsData.length; i++) {
      final student = data.studentsData[i];
      final row = studentStartRow + i;

      // Serial number is already in the template - DO NOT write it

      // Get template style for student data and ensure center alignment
      final templateDataCell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: nameColumn,
          rowIndex: studentStartRow,
        ),
      );
      var studentDataStyle = templateDataCell.cellStyle;
      if (studentDataStyle != null) {
        studentDataStyle = studentDataStyle.copyWith(
          horizontalAlignVal: HorizontalAlign.Center,
          verticalAlignVal: VerticalAlign.Center,
          boldVal: true, // Make student names and scores bold
          fontSizeVal: 12, // Bigger font
        );
      }

      // Student name in column C (nameColumn = 2)
      final nameCell = CellIndex.indexByColumnRow(
        columnIndex: nameColumn,
        rowIndex: row,
      );
      sheet.updateCell(nameCell, TextCellValue(student.student.name));
      // Apply center-aligned style
      if (studentDataStyle != null) {
        sheet.cell(nameCell).cellStyle = studentDataStyle;
      }

      // Fill scores for each week in the selected group
      for (int w = 0; w < weekNumbers.length && w < 5; w++) {
        final weekNo = weekNumbers[w];
        final weekStartCol = firstWeekStartCol + (w * columnsPerWeek);

        // Fill each evaluation type for this week
        for (int e = 0; e < evalIds.length; e++) {
          final score = student.getScoreForWeek(weekNo, evalIds[e]);
          if (score > 0) {
            final scoreCell = CellIndex.indexByColumnRow(
              columnIndex: weekStartCol + e,
              rowIndex: row,
            );
            sheet.updateCell(scoreCell, IntCellValue(score));
            // Apply center-aligned style
            if (studentDataStyle != null) {
              sheet.cell(scoreCell).cellStyle = studentDataStyle;
            }
          }
        }

        // Fill total for this week (8th column in the week block)
        final total = student.getTotalForWeek(weekNo);
        if (total > 0) {
          final totalCell = CellIndex.indexByColumnRow(
            columnIndex: weekStartCol + 7, // Total column
            rowIndex: row,
          );
          sheet.updateCell(totalCell, IntCellValue(total));
          // Apply center-aligned style
          if (studentDataStyle != null) {
            sheet.cell(totalCell).cellStyle = studentDataStyle;
          }
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
    // متوسط الفصل الدراسي الثاني section starts after week 18 (3 weeks on page 4)
    // averageStartCol = firstWeekStartCol + (weekCount * columnsPerWeek)
    final averageStartCol = firstWeekStartCol + (weekCount * columnsPerWeek);

    // Get template style and ensure center alignment
    final templateDataCell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: nameColumn,
        rowIndex: studentStartRow,
      ),
    );
    var avgDataStyle = templateDataCell.cellStyle;
    if (avgDataStyle != null) {
      avgDataStyle = avgDataStyle.copyWith(
        horizontalAlignVal: HorizontalAlign.Center,
        verticalAlignVal: VerticalAlign.Center,
        boldVal: true,
        fontSizeVal: 12,
      );
    }

    // Calculate average for each evaluation type across all 18 weeks (7 subjects only)
    for (int e = 0; e < evalIds.length; e++) {
      int evalTotal = 0;
      int weeksWithScore = 0;

      for (int w = 1; w <= 18; w++) {
        final score = student.getScoreForWeek(w, evalIds[e]);
        if (score > 0) {
          evalTotal += score;
          weeksWithScore++;
        }
      }

      // Calculate average for this evaluation type
      // ALWAYS write the average, even if it's 0
      final evalAvg = weeksWithScore > 0
          ? (evalTotal / weeksWithScore).round()
          : 0;
      final evalCell = CellIndex.indexByColumnRow(
        columnIndex: averageStartCol + e,
        rowIndex: row,
      );

      sheet.updateCell(evalCell, IntCellValue(evalAvg));

      // Apply center-aligned style
      if (avgDataStyle != null) {
        sheet.cell(evalCell).cellStyle = avgDataStyle;
      }
    }

    // Calculate TOTAL Average (Sum of averages)
    // This goes into the 8th column (Index 7)
    int totalAvg = 0;
    int weeksWithTotal = 0;

    for (int w = 1; w <= 18; w++) {
      final total = student.getTotalForWeek(w);
      if (total > 0) {
        totalAvg += total;
        weeksWithTotal++;
      }
    }

    final finalTotalAvg = weeksWithTotal > 0
        ? (totalAvg / weeksWithTotal).round()
        : 0;

    final totalCell = CellIndex.indexByColumnRow(
      columnIndex: averageStartCol + 7,
      rowIndex: row,
    );
    sheet.updateCell(totalCell, IntCellValue(finalTotalAvg));
    if (avgDataStyle != null) {
      sheet.cell(totalCell).cellStyle = avgDataStyle;
    }
  }
}

// =======================================================
// 2) 3–6 ابتدائي (Primary)
// =======================================================

class Primary36Config extends ExcelTemplateConfig {
  @override
  String get templateName => 'كشف فارغ اعمال السنة من 3ل6 ابتدائى.xlsx';

  // Metadata cells
  final Map<String, CellIndex> metaCells = {
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
    'subject': CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: 3), // X4
  };

  // Student data starts at row 8 (0-indexed) -> Excel Row 9
  final int studentStartRow = 8;
  final int serialColumn = 1; // B
  final int nameColumn = 2; // C

  // Week structure
  final int firstWeekCol = 3; // D
  final int colsPerWeek = 6;

  // Columns Mapping (Right to Left in Sheet / Index 0..4)
  final List<String> evalOrder = [
    'primary_homework', // Col 0
    'primary_activity', // Col 1
    'primary_weekly', // Col 2
    'primary_performance', // Col 3
    'primary_attendance', // Col 4
  ];

  // Arabic Labels for Headers matching evalOrder
  final List<String> evalLabels = [
    'كراس الواجب',
    'كراس النشاط',
    'التقييم الأسبوعي',
    'أداء صفي',
    'مهام و مواظبة',
  ];

  @override
  void fillMetadata(Sheet sheet, PrintDataEntity data) {
    // C1: Governorate
    final govCell = sheet.cell(metaCells['governorate']!);
    final govTemplate = govCell.value?.toString() ?? 'مديرية التربية والتعليم ';
    sheet.updateCell(
      metaCells['governorate']!,
      TextCellValue(
        govTemplate.replaceAll(RegExp(r'[\.…]+'), data.governorate),
      ),
    );

    // C2: Administration
    final adminCell = sheet.cell(metaCells['administration']!);
    final adminTemplate = adminCell.value?.toString() ?? 'إدارة ';
    sheet.updateCell(
      metaCells['administration']!,
      TextCellValue(
        adminTemplate.replaceAll(RegExp(r'[\.…]+'), data.administration),
      ),
    );

    // C3: School
    final schoolCell = sheet.cell(metaCells['school']!);
    final schoolTemplate = schoolCell.value?.toString() ?? 'مدرسة ';
    sheet.updateCell(
      metaCells['school']!,
      TextCellValue(
        schoolTemplate.replaceAll(RegExp(r'[\.…]+'), data.classEntity.school),
      ),
    );

    // M4: Class
    // The template might have "سجل رصد .... صف ..."
    final classCell = sheet.cell(metaCells['class']!);
    final classTemplate = classCell.value?.toString() ?? 'فصل ';
    final classText = classTemplate.replaceAll(
      RegExp(r'[\.…]+'),
      '   ${data.classEntity.name}',
    );
    sheet.updateCell(metaCells['class']!, TextCellValue(classText));

    // X4: Subject
    final subjectCell = sheet.cell(metaCells['subject']!);
    final subjectTemplate = subjectCell.value?.toString() ?? 'مادة : ';
    final subjectText = subjectTemplate.replaceAll(
      RegExp(r'[\.…]+'),
      data.classEntity.subject,
    );
    sheet.updateCell(metaCells['subject']!, TextCellValue(subjectText));

    // Clear residuals if necessary
    sheet.updateCell(CellIndex.indexByString('T4'), TextCellValue(''));
    sheet.updateCell(CellIndex.indexByString('I4'), TextCellValue(''));

    // Set row heights for headers
    sheet.setRowHeight(3, 120.0); // Metadata row
    sheet.setRowHeight(5, 180.0); // Eval headers (Row 6)
    sheet.setRowHeight(6, 180.0); // Eval headers (Row 7)
  }

  @override
  void fillWeekHeaders(
    Sheet sheet,
    List<int> weeks,
    Map<int, DateTime> weekStartDates,
  ) {
    // 1. Get Template Styles
    // Week Header Style (Row 5 / Index 4)
    final templateWeekCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: firstWeekCol, rowIndex: 4),
    );
    var weekStyle = templateWeekCell.cellStyle;
    weekStyle = weekStyle?.copyWith(
      horizontalAlignVal: HorizontalAlign.Center,
      verticalAlignVal: VerticalAlign.Center,
      boldVal: true,
      fontSizeVal: 12,
    );

    // Eval Header Style (Row 7 / Index 6)
    final templateEvalCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: firstWeekCol, rowIndex: 6),
    );
    var evalStyle = templateEvalCell.cellStyle;
    evalStyle = evalStyle?.copyWith(
      rotationVal: 90, // Vertical Rotation
      horizontalAlignVal: HorizontalAlign.Center,
      verticalAlignVal: VerticalAlign.Center,
      boldVal: true,
      fontSizeVal: 12,
    );

    // 2. Loop Weeks
    for (int i = 0; i < weeks.length; i++) {
      final weekNo = weeks[i];
      final colIndex = firstWeekCol + (i * colsPerWeek);

      // A. Week Title
      final date = weekStartDates[weekNo];
      final dateStr = date != null ? DateFormat('d/M').format(date) : '';
      final weekTitle = 'الأسبوع $weekNo $dateStr';

      final weekCellIndex = CellIndex.indexByColumnRow(
        columnIndex: colIndex,
        rowIndex: 4,
      );
      sheet.updateCell(weekCellIndex, TextCellValue(weekTitle));
      if (weekStyle != null) sheet.cell(weekCellIndex).cellStyle = weekStyle;

      // B. Evaluation Headers
      for (int e = 0; e < evalLabels.length; e++) {
        final evalCellIndex = CellIndex.indexByColumnRow(
          columnIndex: colIndex + e,
          rowIndex: 6,
        );
        sheet.updateCell(evalCellIndex, TextCellValue(evalLabels[e]));
        if (evalStyle != null) sheet.cell(evalCellIndex).cellStyle = evalStyle;
      }

      // C. Total Header
      final totalCellIndex = CellIndex.indexByColumnRow(
        columnIndex: colIndex + evalLabels.length,
        rowIndex: 6,
      );
      sheet.updateCell(totalCellIndex, TextCellValue('المجموع'));
      if (evalStyle != null) sheet.cell(totalCellIndex).cellStyle = evalStyle;
    }

    // 3. Clear unused weeks if < 5
    if (weeks.length < 5) {
      for (int w = weeks.length; w < 5; w++) {
        final colIndex = firstWeekCol + (w * colsPerWeek);
        // Clear logic... (simplified to just clearing values for cleanliness)
        for (int col = 0; col < colsPerWeek; col++) {
          for (int r = 4; r <= 6; r++) {
            sheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex + col,
                rowIndex: r,
              ),
              TextCellValue(''),
            );
          }
        }
      }
    }

    // 4. Page 4 Headers (Semester Average)
    if (weeks.contains(18)) {
      final avgStartCol = firstWeekCol + (weeks.length * colsPerWeek);

      // "Semester Average" merged title
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: avgStartCol, rowIndex: 4),
        CellIndex.indexByColumnRow(
          columnIndex: avgStartCol + colsPerWeek - 1,
          rowIndex: 4,
        ),
        customValue: TextCellValue('متوسط الفصل الدراسي الثاني'),
      );
      final avgTitleCell = CellIndex.indexByColumnRow(
        columnIndex: avgStartCol,
        rowIndex: 4,
      );
      sheet.updateCell(
        avgTitleCell,
        TextCellValue('متوسط الفصل الدراسي الثاني'),
      );
      if (weekStyle != null) sheet.cell(avgTitleCell).cellStyle = weekStyle;

      // Eval Headers for Average
      for (int e = 0; e < evalLabels.length; e++) {
        final cellIndex = CellIndex.indexByColumnRow(
          columnIndex: avgStartCol + e,
          rowIndex: 6,
        );
        sheet.updateCell(cellIndex, TextCellValue(evalLabels[e]));
        if (evalStyle != null) sheet.cell(cellIndex).cellStyle = evalStyle;
      }
      // Total for Average
      final avgTotalIndex = CellIndex.indexByColumnRow(
        columnIndex: avgStartCol + evalLabels.length,
        rowIndex: 6,
      );
      sheet.updateCell(avgTotalIndex, TextCellValue('المجموع'));
      if (evalStyle != null) sheet.cell(avgTotalIndex).cellStyle = evalStyle;

      // =======================================================
      // 5. Monthly Tests Headers (Page 4 Only)
      // =======================================================
      // Starts at Col 27 (AB)
      final monthlyStartCol = 27;

      // Group Header "اختبارات الشهور" (Row 6 / Index 5 - Merged?)
      // Assuming it spans columns 27, 28, 29, 30
      // Columns: [27: March], [28: April], [29: Avg], [30: Notes]
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: monthlyStartCol, rowIndex: 5),
        CellIndex.indexByColumnRow(
          columnIndex: monthlyStartCol + 3,
          rowIndex: 5,
        ),
        customValue: TextCellValue('اختبارات الشهور'),
      );
      final monthlyTitleCell = CellIndex.indexByColumnRow(
        columnIndex: monthlyStartCol,
        rowIndex: 5,
      );
      sheet.updateCell(monthlyTitleCell, TextCellValue('اختبارات الشهور'));
      if (weekStyle != null) sheet.cell(monthlyTitleCell).cellStyle = weekStyle;

      // Sub-headers (Row 7 / Index 6)
      // [27] March, [28] April, [29] Avg, [30] Notes
      final monthlyLabels = [
        'اختبار مارس',
        'اختبار ابريل',
        'متوسط الاختبارين',
        'ملاحظات',
      ];

      for (int i = 0; i < monthlyLabels.length; i++) {
        final cellIndex = CellIndex.indexByColumnRow(
          columnIndex: monthlyStartCol + i,
          rowIndex: 6,
        );
        sheet.updateCell(cellIndex, TextCellValue(monthlyLabels[i]));
        if (evalStyle != null) {
          // Let's keep consistent vertical style
          sheet.cell(cellIndex).cellStyle = evalStyle;
        }
      }

      // Max Scores for Monthly Tests (Row 8 / Index 7)
      // March=10, April=10, Avg=10
      final monthlyMaxScores = [10, 10, 10];
      for (int i = 0; i < monthlyMaxScores.length; i++) {
        final cellIndex = CellIndex.indexByColumnRow(
          columnIndex: monthlyStartCol + i,
          rowIndex: 7, // Row 8
        );
        sheet.updateCell(cellIndex, IntCellValue(monthlyMaxScores[i]));
        // Style: Centered, Bold? (Week Style)
        if (weekStyle != null) {
          sheet.cell(cellIndex).cellStyle = weekStyle;
        }
      }
    }
  }

  @override
  void fillStudents(
    Sheet sheet,
    PrintDataEntity data, {
    List<int>? weeksOverride,
  }) {
    final weekNumbers = weeksOverride ?? data.weekNumbers;
    final isPage4 = weekNumbers.contains(18);

    // Get Base Style from Template (first student name cell)
    final templateDataCell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: nameColumn,
        rowIndex: studentStartRow,
      ),
    );
    var baseStyle = templateDataCell.cellStyle?.copyWith(
      horizontalAlignVal: HorizontalAlign.Center,
      verticalAlignVal: VerticalAlign.Center,
      boldVal: true,
      fontSizeVal: 12,
    );

    for (int i = 0; i < data.studentsData.length; i++) {
      final student = data.studentsData[i];
      final row = studentStartRow + i;

      // Name
      final nameCell = CellIndex.indexByColumnRow(
        columnIndex: nameColumn,
        rowIndex: row,
      );
      sheet.updateCell(nameCell, TextCellValue(student.student.name));
      if (baseStyle != null) sheet.cell(nameCell).cellStyle = baseStyle;

      // Weekly Scores
      for (int w = 0; w < weekNumbers.length; w++) {
        final weekNo = weekNumbers[w];
        final weekStartCol = firstWeekCol + (w * colsPerWeek);

        for (int e = 0; e < evalOrder.length; e++) {
          final score = student.getScoreForWeek(weekNo, evalOrder[e]);
          if (score > 0) {
            final cellIndex = CellIndex.indexByColumnRow(
              columnIndex: weekStartCol + e,
              rowIndex: row,
            );
            sheet.updateCell(cellIndex, IntCellValue(score));
            if (baseStyle != null) sheet.cell(cellIndex).cellStyle = baseStyle;
          }
        }
        // Total
        final total = student.getTotalForWeek(weekNo);
        if (total > 0) {
          final cellIndex = CellIndex.indexByColumnRow(
            columnIndex: weekStartCol + evalOrder.length,
            rowIndex: row,
          );
          sheet.updateCell(cellIndex, IntCellValue(total));
          if (baseStyle != null) sheet.cell(cellIndex).cellStyle = baseStyle;
        }
      }

      // Semester Average (Page 4)
      if (isPage4) {
        final avgStartCol = firstWeekCol + (weekNumbers.length * colsPerWeek);

        for (int e = 0; e < evalOrder.length; e++) {
          final evalId = evalOrder[e];
          int sum = 0;
          int count = 0;
          for (int w = 1; w <= 18; w++) {
            if (student.weeklyScores?.containsKey(w) == true) {
              final s = student.getScoreForWeek(w, evalId);
              if (s > 0) {
                sum += s;
                count++;
              }
            }
          }
          final avg = count > 0 ? (sum / count).round() : 0;
          if (avg > 0) {
            final cellIndex = CellIndex.indexByColumnRow(
              columnIndex: avgStartCol + e,
              rowIndex: row,
            );
            sheet.updateCell(cellIndex, IntCellValue(avg));
            if (baseStyle != null) sheet.cell(cellIndex).cellStyle = baseStyle;
          }
        }

        // Total Average
        int sumTotal = 0;
        int countTotal = 0;
        for (int w = 1; w <= 18; w++) {
          final t = student.getTotalForWeek(w);
          if (t > 0) {
            sumTotal += t;
            countTotal++;
          }
        }
        final avgTotal = countTotal > 0 ? (sumTotal / countTotal).round() : 0;
        if (avgTotal > 0) {
          final cellIndex = CellIndex.indexByColumnRow(
            columnIndex: avgStartCol + evalOrder.length,
            rowIndex: row,
          );
          sheet.updateCell(cellIndex, IntCellValue(avgTotal));
          if (baseStyle != null) sheet.cell(cellIndex).cellStyle = baseStyle;
        }

        // Monthly Exams (Col 27+)
        // Verify columns:
        // If 18 weeks -> 3 chunks of 5 + 1 chunk of 3.
        // Week start cols: 3, 9, 15...
        // Page 4:
        // Weeks 16 (Col 3), 17 (Col 9), 18 (Col 15).
        // Avg Start: 3 + (3 * 6) = 21. Correct.
        // Monthly Start: 27. Correct.

        // Monthly Headers were set in fillWeekHeaders?
        // I missed adding Monthly Headers in fillWeekHeaders. I should add them there.
        // For now, let's fill data.

        final march = student.monthlyExamScores?['first_month_exam'] ?? 0;
        final april = student.monthlyExamScores?['second_month_exam'] ?? 0;
        final ma = student.monthlyExamScores?['months_exam_average'] ?? 0;

        if (march > 0) {
          final c = CellIndex.indexByColumnRow(columnIndex: 27, rowIndex: row);
          sheet.updateCell(c, IntCellValue(march));
          if (baseStyle != null) sheet.cell(c).cellStyle = baseStyle;
        }
        if (april > 0) {
          final c = CellIndex.indexByColumnRow(columnIndex: 28, rowIndex: row);
          sheet.updateCell(c, IntCellValue(april));
          if (baseStyle != null) sheet.cell(c).cellStyle = baseStyle;
        }
        if (ma > 0) {
          final c = CellIndex.indexByColumnRow(columnIndex: 29, rowIndex: row);
          sheet.updateCell(c, IntCellValue(ma));
          if (baseStyle != null) sheet.cell(c).cellStyle = baseStyle;
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

  // Metadata positions (Standard Layout)
  final Map<String, CellIndex> metaCells = {
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
    'class': CellIndex.indexByColumnRow(
      columnIndex: 12,
      rowIndex: 3,
    ), // M4 (Assumed)
  };

  // Student data starts at row 8 (0-indexed: 7)
  final int studentStartRow = 7;
  final int serialColumn = 1; // B
  final int nameColumn = 2; // C

  // Week structure: 4 cols per week
  final int firstWeekCol = 3; // D
  final int colsPerWeek = 4;

  // Eval Order (Right to Left: Col 0..3)
  final List<String> evalIds = [
    'prep_hw', // Col 0
    'prep_activity', // Col 1
    'prep_weekly', // Col 2
    'prep_attendance', // Col 3
  ];

  // Arabic Labels
  final List<String> evalLabels = [
    'الواجب',
    'النشاط',
    'التقييم الأسبوعي',
    'سلوك و مواظبة',
  ];

  @override
  void fillMetadata(Sheet sheet, PrintDataEntity d) {
    // C1: Governorate
    final govCell = sheet.cell(metaCells['governorate']!);
    final govTemplate = govCell.value?.toString() ?? 'مديرية التربية والتعليم ';
    sheet.updateCell(
      metaCells['governorate']!,
      TextCellValue(govTemplate.replaceAll(RegExp(r'[\.…]+'), d.governorate)),
    );

    // C2: Administration
    final adminCell = sheet.cell(metaCells['administration']!);
    final adminTemplate = adminCell.value?.toString() ?? 'إدارة ';
    sheet.updateCell(
      metaCells['administration']!,
      TextCellValue(
        adminTemplate.replaceAll(RegExp(r'[\.…]+'), d.administration),
      ),
    );

    // C3: School
    final schoolCell = sheet.cell(metaCells['school']!);
    final schoolTemplate = schoolCell.value?.toString() ?? 'مدرسة ';
    sheet.updateCell(
      metaCells['school']!,
      TextCellValue(
        schoolTemplate.replaceAll(RegExp(r'[\.…]+'), d.classEntity.school),
      ),
    );

    // L4: Subject
    final subjectCell = sheet.cell(metaCells['subject']!);
    final subjectTemplate = subjectCell.value?.toString() ?? 'مادة ';
    sheet.updateCell(
      metaCells['subject']!,
      TextCellValue(
        subjectTemplate.replaceAll(RegExp(r'[\.…]+'), d.classEntity.subject),
      ),
    );

    // M4: Class (Try to preserve if exists)
    final classCell = sheet.cell(metaCells['class']!);
    final classTemplate = classCell.value?.toString() ?? 'فصل ';
    // If template is empty or simple, just append name
    final classText = classTemplate.replaceAll(
      RegExp(r'[\.…]+'),
      '   ${d.classEntity.name}',
    );
    sheet.updateCell(metaCells['class']!, TextCellValue(classText));
  }

  @override
  void fillWeekHeaders(
    Sheet sheet,
    List<int> weeks,
    Map<int, DateTime> weekStartDates,
  ) {
    // 1. Get/Define Styles
    // Week Header (Row 6 / Index 5 - inferred from previous code)
    final templateWeekCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: firstWeekCol, rowIndex: 5),
    );
    var weekStyle = templateWeekCell.cellStyle?.copyWith(
      horizontalAlignVal: HorizontalAlign.Center,
      verticalAlignVal: VerticalAlign.Center,
      boldVal: true,
      fontSizeVal: 12,
    );

    // Eval Header Style (Row 7 / Index 6 - Assumed below Week Header)
    // Checking row 6 (Index 5) used for Week Title.
    // So Row 7 (Index 6) should be headers.
    final templateEvalCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: firstWeekCol, rowIndex: 6),
    );
    var evalStyle = templateEvalCell.cellStyle?.copyWith(
      rotationVal: 90, // Consistent with others
      horizontalAlignVal: HorizontalAlign.Center,
      verticalAlignVal: VerticalAlign.Center,
      boldVal: true,
      fontSizeVal: 12,
    );

    for (int i = 0; i < weeks.length; i++) {
      final weekNo = weeks[i];
      final colIndex = firstWeekCol + (i * colsPerWeek);

      // A. Week Title at Row 6 (Index 5)
      final text = 'الأسبوع $weekNo';
      final weekCell = CellIndex.indexByColumnRow(
        columnIndex: colIndex,
        rowIndex: 5,
      );
      sheet.updateCell(weekCell, TextCellValue(text));
      if (weekStyle != null) sheet.cell(weekCell).cellStyle = weekStyle;

      // B. Eval Headers at Row 7 (Index 6)
      for (int e = 0; e < evalLabels.length; e++) {
        final cellIndex = CellIndex.indexByColumnRow(
          columnIndex: colIndex + e,
          rowIndex: 6,
        );
        sheet.updateCell(cellIndex, TextCellValue(evalLabels[e]));
        if (evalStyle != null) sheet.cell(cellIndex).cellStyle = evalStyle;
      }
    }

    // Clear unused weeks?
    if (weeks.length < 5) {
      for (int w = weeks.length; w < 5; w++) {
        final colIndex = firstWeekCol + (w * colsPerWeek);
        for (int c = 0; c < colsPerWeek; c++) {
          for (int r = 5; r <= 6; r++) {
            sheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex + c,
                rowIndex: r,
              ),
              TextCellValue(''),
            );
          }
        }
      }
    }
  }

  @override
  void fillStudents(
    Sheet sheet,
    PrintDataEntity d, {
    List<int>? weeksOverride,
  }) {
    final weekNumbers = weeksOverride ?? d.weekNumbers;

    // Get Base Style
    final templateDataCell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: nameColumn,
        rowIndex: studentStartRow,
      ),
    );
    var baseStyle = templateDataCell.cellStyle?.copyWith(
      horizontalAlignVal: HorizontalAlign.Center,
      verticalAlignVal: VerticalAlign.Center,
      boldVal: true,
      fontSizeVal: 12,
    );

    for (int i = 0; i < d.studentsData.length; i++) {
      final student = d.studentsData[i];
      final row = studentStartRow + i;

      // Serial
      final serialCell = CellIndex.indexByColumnRow(
        columnIndex: serialColumn,
        rowIndex: row,
      );
      sheet.updateCell(serialCell, IntCellValue(i + 1));
      if (baseStyle != null) sheet.cell(serialCell).cellStyle = baseStyle;

      // Name
      final nameCell = CellIndex.indexByColumnRow(
        columnIndex: nameColumn,
        rowIndex: row,
      );
      sheet.updateCell(nameCell, TextCellValue(student.student.name));
      if (baseStyle != null) sheet.cell(nameCell).cellStyle = baseStyle;

      // Scores
      for (int w = 0; w < weekNumbers.length && w < 5; w++) {
        final weekNo = weekNumbers[w];
        final weekStartCol = firstWeekCol + (w * colsPerWeek);

        for (int e = 0; e < evalIds.length; e++) {
          final score = student.getScoreForWeek(weekNo, evalIds[e]);
          if (score > 0) {
            final cellIndex = CellIndex.indexByColumnRow(
              columnIndex: weekStartCol + e,
              rowIndex: row,
            );
            sheet.updateCell(cellIndex, IntCellValue(score));
            if (baseStyle != null) sheet.cell(cellIndex).cellStyle = baseStyle;
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

  // Secondary uses a fixed semester template (3 months).
  // We do NOT want to chunk it into 5-week sheets.
  // We want ONE sheet containing all data.
  @override
  List<List<int>> getWeekChunks(PrintDataEntity data) {
    // Return a single chunk containing all weeks so exportToExcel loops once.
    return [data.weekNumbers];
  }

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
  void fillStudents(
    Sheet sheet,
    PrintDataEntity d, {
    List<int>? weeksOverride,
  }) {
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
  String get templateName => 'attendance_sheet.xlsx';

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

  final int studentStartRow = 6; // Index 6 (Row 7 in Excel)
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
  void fillWeekHeaders(
    Sheet sheet,
    List<int> weeks,
    Map<int, DateTime> weekStartDates,
  ) {
    // Week Header is likely at Row 4 (0-indexed) or 5
    // Based on PrePrimary/Primary, usually Row 4 (Excel Row 5)
    // Debug output says "Row 5 (Index 4)" has week headers.
    const int weekHeaderRow = 4;

    // Get Template Style from first week
    final templateWeekCell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: firstWeekCol,
        rowIndex: weekHeaderRow,
      ),
    );
    var weekStyle = templateWeekCell.cellStyle?.copyWith(
      horizontalAlignVal: HorizontalAlign.Center,
      verticalAlignVal: VerticalAlign.Center,
      boldVal: true,
      fontSizeVal: 12,
    );

    for (int i = 0; i < weeks.length; i++) {
      final weekNo = weeks[i];
      final colIndex = firstWeekCol + (i * daysPerWeek);

      // Update Week Title
      final date = weekStartDates[weekNo];
      final dateStr = date != null ? DateFormat('d/M').format(date) : '';
      final weekTitle = 'الأسبوع $weekNo  $dateStr';

      final cellIndex = CellIndex.indexByColumnRow(
        columnIndex: colIndex,
        rowIndex: weekHeaderRow,
      );
      sheet.updateCell(cellIndex, TextCellValue(weekTitle));
      if (weekStyle != null) sheet.cell(cellIndex).cellStyle = weekStyle;
    }

    // Clear unused weeks if < 5
    if (weeks.length < 5) {
      for (int w = weeks.length; w < 5; w++) {
        final colIndex = firstWeekCol + (w * daysPerWeek);
        // Clear main week header
        sheet.updateCell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: weekHeaderRow,
          ),
          TextCellValue(''),
        );

        // Clear sub-headers/days (Rows 5, 6, 7 assumed)
        // Debug output Row 6 (Index 5) has days.
        // And data starts at Index 6 (Row 7).
        // So we clear Row 5 (Index 5).
        for (int col = 0; col < daysPerWeek; col++) {
          for (
            int row = weekHeaderRow;
            row <= studentStartRow - 1; // Clear up to start row
            row++
          ) {
            sheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex + col,
                rowIndex: row,
              ),
              TextCellValue(''),
            );
          }
        }
      }
    }
  }

  @override
  void fillStudents(
    Sheet sheet,
    PrintDataEntity data, {
    List<int>? weeksOverride,
  }) {
    final weekNumbers = weeksOverride ?? data.weekNumbers;

    for (int i = 0; i < data.studentsData.length; i++) {
      final student = data.studentsData[i];
      final row = studentStartRow + i;

      // Merge Serial (Index 1) and Name (Index 2) columns and write Name
      // This effectively "replaces" the serial column with the name, using the combined space.
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: serialColumn, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: nameColumn, rowIndex: row),
        customValue: TextCellValue(student.student.name),
      );

      // Apply style (Center, Bold)
      final nameCell = CellIndex.indexByColumnRow(
        columnIndex: serialColumn,
        rowIndex: row,
      );
      // We can use style from Row 8 (Index 7) which was "2" (probably standard font)
      // Or just create a style.
      sheet.cell(nameCell).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bold: true,
        fontSize: 12,
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

            String mark = '';
            // Default: If explicitly present -> ✓. If explicitly absent -> X.
            // If unknown -> nothing.
            if (status == AttendanceStatus.absent) {
              mark = 'X';
            } else if (status == AttendanceStatus.excused) {
              mark = 'ع';
            } else if (status == AttendanceStatus.present) {
              mark = '✓';
            }

            if (mark.isNotEmpty) {
              final cellIndex = CellIndex.indexByColumnRow(
                columnIndex: weekStartCol + d,
                rowIndex: row,
              );
              sheet.updateCell(cellIndex, TextCellValue(mark));

              // Apply centered style
              sheet.cell(cellIndex).cellStyle = CellStyle(
                horizontalAlign: HorizontalAlign.Center,
                verticalAlign: VerticalAlign.Center,
                bold: true,
                fontSize: 12,
              );
            }
          }
        }
      }
    }
  }
}
