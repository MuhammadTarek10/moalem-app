// =============================================================================
// StudentAssessmentExcelExporter
// =============================================================================
// WHY TEMPLATE-BASED EXCEL EXPORT?
// ---------------------------------
// The Excel template is the SINGLE SOURCE OF TRUTH for:
// - Layout (merged cells, column widths, row heights)
// - Styling (fonts, borders, colors, RTL direction)
// - Static content (headers, logos, labels)
// - Formulas (if any exist in the template)
//
// This approach ensures:
// 1. The exported file looks IDENTICAL to the approved template
// 2. Non-developers can update the template without code changes
// 3. No risk of styling drift between code and expectations
// 4. Faster development - no need to recreate complex Arabic layouts in code
//
// IMPORTANT: syncfusion_flutter_xlsio can ONLY CREATE files, not READ them.
// Therefore, we use the 'excel' package to LOAD the template and MODIFY it.
// This preserves ALL template styling - we only inject data into cells.
// =============================================================================

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// =============================================================================
// DATA MODELS
// =============================================================================

/// Represents a single student's assessment data across all weeks.
///
/// Each week contains 7 evaluation scores + 1 total (calculated or provided).
/// The order of scores in [weeklyScores] must match the template columns.
class StudentAssessmentData {
  /// Row index in the template (1-based). If null, will be auto-assigned.
  final int? rowIndex;

  /// Student name (Arabic)
  final String name;

  /// Weekly scores: Map of weekNumber to List of scores
  /// Week numbers are 1-5.
  /// Each list contains 7 evaluation scores in template column order:
  /// [0] كراس اداء صفي      (Classroom Performance) - max 20
  /// [1] كراس الواجب        (Homework Book) - max 20
  /// [2] كراس النشاط        (Activity Book) - max 20
  /// [3] تقييم أسبوعي       (Weekly Assessment) - max 20
  /// [4] مهام شفهية         (Oral Tasks) - max 10
  /// [5] مهام مهارية        (Skill Tasks) - max 5
  /// [6] حضور و مواظبة      (Attendance) - max 5
  final Map<int, List<int>> weeklyScores;

  const StudentAssessmentData({
    this.rowIndex,
    required this.name,
    required this.weeklyScores,
  });

  /// Calculate total for a specific week (sum of 7 scores, max 100)
  int getWeekTotal(int weekNumber) {
    final scores = weeklyScores[weekNumber];
    if (scores == null || scores.isEmpty) return 0;
    return scores.fold(0, (sum, score) => sum + score);
  }
}

/// Metadata for the export (school info, date, etc.)
class AssessmentExportMetadata {
  final String administration; // إدارة
  final String school; // مدرسة
  final String subject; // مادة
  final String academicYear; // السنة الدراسية
  final Map<int, DateTime>?
  weekStartDates; // Optional: week number -> start date

  const AssessmentExportMetadata({
    required this.administration,
    required this.school,
    required this.subject,
    required this.academicYear,
    this.weekStartDates,
  });
}

// =============================================================================
// EXCEL COLUMN MAPPING CONFIGURATION
// =============================================================================
// WHY FIXED COLUMN INDEXES?
// -------------------------
// The template has a fixed structure. Each week block occupies 8 columns:
// - 7 evaluation columns + 1 total column
//
// If the template changes, update ONLY this configuration section.
// DO NOT scatter magic numbers throughout the code.
// =============================================================================

class ExcelColumnConfig {
  // -------------------------------------------------------------------------
  // Student info columns (0-based indexing for excel package)
  // -------------------------------------------------------------------------
  static const int serialNumberColumn = 0; // Column A: م
  static const int studentNameColumn = 1; // Column B: الاسم

  // -------------------------------------------------------------------------
  // Row configuration (0-based indexing for excel package)
  // -------------------------------------------------------------------------
  // Row 0: Week header (e.g., "الأسبوع الأول 2026\1\7")
  // Row 1: "جوانب التقييم" header
  // Row 2: Evaluation names (vertical text)
  // Row 3: Max scores (20, 20, 20, 20, 10, 5, 5, 100)
  // Row 4+: Student data
  static const int firstStudentRow = 4;

  // -------------------------------------------------------------------------
  // Week structure
  // -------------------------------------------------------------------------
  static const int evaluationsPerWeek = 7; // Number of evaluation columns
  static const int columnsPerWeek = 8; // Evaluations + total column

  // -------------------------------------------------------------------------
  // Week start columns (0-based)
  // Each week starts at a specific column. Adjust if template changes.
  // -------------------------------------------------------------------------
  static const Map<int, int> weekStartColumns = {
    1: 2, // Column C (index 2)
    2: 10, // Column K (index 10)
    3: 18, // Column S (index 18)
    4: 26, // Column AA (index 26)
    5: 34, // Column AI (index 34)
  };

  /// Get the column index for a specific evaluation in a specific week
  /// [weekNumber]: 1-5
  /// [evaluationIndex]: 0-6 (order matches StudentAssessmentData.weeklyScores)
  static int getEvaluationColumn(int weekNumber, int evaluationIndex) {
    final weekStart = weekStartColumns[weekNumber] ?? 2;
    return weekStart + evaluationIndex;
  }

  /// Get the total column for a specific week
  static int getTotalColumn(int weekNumber) {
    final weekStart = weekStartColumns[weekNumber] ?? 2;
    return weekStart + evaluationsPerWeek; // 8th column in the block
  }
}

// =============================================================================
// MAIN EXPORTER SERVICE (TEMPLATE-BASED)
// =============================================================================

/// Production-grade Excel exporter that preserves ALL template styling.
///
/// This service:
/// - Loads an existing Excel template from assets
/// - Injects student data into predefined cells (NO styling changes)
/// - Preserves merged cells, borders, fonts, colors, and formulas
/// - Saves the file with a meaningful Arabic filename
///
/// Usage:
/// ```dart
/// final exporter = StudentAssessmentExcelExporter();
/// final filePath = await exporter.export(
///   metadata: metadata,
///   students: studentList,
///   weeksToExport: [1, 2, 3],
/// );
/// // Share or open filePath
/// ```
class StudentAssessmentExcelExporter {
  /// Template asset path (can be overridden via constructor)
  final String templateAssetPath;

  StudentAssessmentExcelExporter({
    this.templateAssetPath =
        'assets/files/كشف فارغ اعمال السنة اولى وتانية ابتدائى.xlsx',
  });

  /// Export student assessment data to Excel.
  ///
  /// Returns the absolute path to the saved file.
  ///
  /// [metadata]: School/class information
  /// [students]: List of students with their scores
  /// [weeksToExport]: Which weeks to include (1-5)
  Future<String> export({
    required AssessmentExportMetadata metadata,
    required List<StudentAssessmentData> students,
    required List<int> weeksToExport,
  }) async {
    // =========================================================================
    // STEP 1: Load template from assets
    // =========================================================================
    final ByteData data = await rootBundle.load(templateAssetPath);
    final Uint8List bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    // Decode Excel file (preserves ALL formatting)
    final excel_pkg.Excel excelFile = excel_pkg.Excel.decodeBytes(bytes);

    // Get first sheet
    if (excelFile.tables.isEmpty) {
      throw Exception('Template has no sheets');
    }
    final String sheetName = excelFile.tables.keys.first;
    final excel_pkg.Sheet sheet = excelFile.tables[sheetName]!;

    // =========================================================================
    // STEP 2: Write week dates (Row 0 in template)
    // =========================================================================
    _writeWeekDates(sheet, metadata, weeksToExport);

    // =========================================================================
    // STEP 3: Write student data
    // =========================================================================
    _writeStudentData(sheet, students, weeksToExport);

    // =========================================================================
    // STEP 4: Save file
    // =========================================================================
    return await _saveFile(excelFile, metadata);
  }

  /// Write week dates to the header row
  void _writeWeekDates(
    excel_pkg.Sheet sheet,
    AssessmentExportMetadata metadata,
    List<int> weeksToExport,
  ) {
    for (final weekNum in weeksToExport) {
      final weekDate = metadata.weekStartDates?[weekNum];
      if (weekDate != null) {
        final startCol = ExcelColumnConfig.weekStartColumns[weekNum] ?? 2;
        final dateStr = '${weekDate.year}\\${weekDate.month}\\${weekDate.day}';
        final weekLabel = 'الأسبوع ${_getArabicOrdinal(weekNum)} $dateStr';

        // Write to merged cell (only need to write to first cell)
        _setCellText(sheet, 0, startCol, weekLabel);
      }
    }
  }

  /// Write all student data to the sheet
  void _writeStudentData(
    excel_pkg.Sheet sheet,
    List<StudentAssessmentData> students,
    List<int> weeksToExport,
  ) {
    int currentRow = ExcelColumnConfig.firstStudentRow;

    for (int i = 0; i < students.length; i++) {
      final student = students[i];

      // Serial number (م)
      _setCellInt(
        sheet,
        currentRow,
        ExcelColumnConfig.serialNumberColumn,
        i + 1,
      );

      // Student name (الاسم)
      _setCellText(
        sheet,
        currentRow,
        ExcelColumnConfig.studentNameColumn,
        student.name,
      );

      // Weekly scores
      for (final weekNum in weeksToExport) {
        _writeWeeklyScores(sheet, currentRow, weekNum, student);
      }

      currentRow++;
    }

    // =========================================================================
    // STEP 3.5: Clean up unused rows (Dynamic Print Area)
    // =========================================================================
    // We assume the template might have pre-formatted rows up to e.g. 100.
    // We want to remove them so the "Print Area" stops at the last student.
    _removeUnusedRows(sheet, currentRow);
  }

  /// Remove unused rows from the sheet to fix the print area
  void _removeUnusedRows(excel_pkg.Sheet sheet, int lastUsedRow) {
    // We scan a reasonable buffer of rows to ensure we catch any pre-formatted empty rows
    // The template likely doesn't go beyond 200 rows for a class list.
    const int maxRowsToCheck = 200;

    // Note: iterating backwards or checking logic matters less here because
    // removeRow shifts indices. But 'excel' package removeRow logic usually
    // requires careful handling. safest is to just loop check.
    // However, the 'excel' package documentation suggests removeRow(index).

    // Strategy: Delete rows from [lastUsedRow] up to [maxRowsToCheck].
    // Since removing a row shifts subsequent rows up, we can repeatedly remove
    // the *same* index (lastUsedRow) if we want to delete a block.
    // BUT, we only want to delete rows that exist in the template.

    // A safer approach with the current 'excel' package is to check maxRows.
    final int totalRows = sheet.maxRows;

    // If we have more rows than data, delete the excess.
    if (totalRows > lastUsedRow) {
      // We delete from the bottom up to avoid index shifting issues affecting our loop range logic
      // (though strictly usually you delete top down for range, or bottom up for index preservation).
      // Actually, if we delete row K, row K+1 becomes K.
      // So to delete a range K..N, we can repeatedly delete row K, (N-K) times.

      int rowsToDelete = totalRows - lastUsedRow;

      // Cap at maxRowsToCheck to prevent infinite loops or huge processing if maxRows is wrong
      if (rowsToDelete > maxRowsToCheck) {
        rowsToDelete = maxRowsToCheck;
      }

      // Remove rows starting from lastUsedRow
      // Note: sheet.maxRows updates dynamically? It should.
      for (int i = 0; i < rowsToDelete; i++) {
        sheet.removeRow(lastUsedRow);
      }
    }
  }

  /// Write a single student's scores for a single week
  void _writeWeeklyScores(
    excel_pkg.Sheet sheet,
    int row,
    int weekNumber,
    StudentAssessmentData student,
  ) {
    final scores = student.weeklyScores[weekNumber];

    // Write individual evaluation scores
    if (scores != null) {
      for (int evalIdx = 0; evalIdx < scores.length && evalIdx < 7; evalIdx++) {
        final score = scores[evalIdx];
        if (score > 0) {
          final colIdx = ExcelColumnConfig.getEvaluationColumn(
            weekNumber,
            evalIdx,
          );
          _setCellInt(sheet, row, colIdx, score);
        }
      }
    }

    // Write week total
    final total = student.getWeekTotal(weekNumber);
    if (total > 0) {
      final totalCol = ExcelColumnConfig.getTotalColumn(weekNumber);
      _setCellInt(sheet, row, totalCol, total);
    }
  }

  /// Set integer value in a cell (preserves existing style)
  void _setCellInt(excel_pkg.Sheet sheet, int row, int col, int value) {
    final cell = sheet.cell(
      excel_pkg.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = excel_pkg.IntCellValue(value);
  }

  /// Set text value in a cell (preserves existing style)
  void _setCellText(excel_pkg.Sheet sheet, int row, int col, String value) {
    final cell = sheet.cell(
      excel_pkg.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = excel_pkg.TextCellValue(value);
  }

  /// Save the workbook to a file with meaningful Arabic name
  Future<String> _saveFile(
    excel_pkg.Excel excelFile,
    AssessmentExportMetadata metadata,
  ) async {
    final List<int>? fileBytes = excelFile.encode();
    if (fileBytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateFormat(
      'yyyyMMdd_HHmmss',
    ).format(DateTime.now());
    final String filename = 'كشف_درجات_${metadata.subject}_$timestamp.xlsx';
    final String filePath = '${directory.path}/$filename';

    final File file = File(filePath);
    await file.writeAsBytes(fileBytes, flush: true);

    return filePath;
  }

  /// Convert week number to Arabic ordinal
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
    };
    return ordinals[number] ?? number.toString();
  }
}
