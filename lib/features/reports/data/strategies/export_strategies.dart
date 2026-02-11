import 'package:intl/intl.dart';
import 'package:moalem/features/reports/domain/entities/excel_export_entity.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

/// Abstract base class for export strategies
/// Replaces the old TemplateStrategy
abstract class TemplateStrategy {
  String get templateName;
  EducationalStage get stage;
  ExportType get exportType;

  // Metadata locations
  final int govRow = 0;
  final int govCol = 2;
  final int adminRow = 1;
  final int adminCol = 2;
  final int schoolRow = 2;
  final int schoolCol = 2;

  Future<Workbook> prepareWorkbook() async {
    final workbook = Workbook();
    // Set RTL for the first sheet
    if (workbook.worksheets.count > 0) {
      workbook.worksheets[0].isRightToLeft = true;
    }
    return workbook;
  }

  Future<void> execute(Workbook workbook, ExcelExportEntity data);

  void fillMetadata(
    Worksheet sheet,
    ExcelExportEntity data, {
    int? classCol,
    int? classRow,
    int? subjectCol,
    int? subjectRow,
    bool isSecondary = false,
  }) {
    final style = createHeaderStyle(sheet.workbook);
    style.hAlign = HAlignType.right;

    // Standard Header (Top Right usually, but RTL means starts at col 1?)
    // In RTL, Col 1 is rightmost.

    // Directorate
    sheet
        .getRangeByIndex(1, 1)
        .setText('مديرية التربية والتعليم: ${data.schoolInfo.governorate}');
    sheet.getRangeByIndex(1, 1).cellStyle = style;
    sheet.getRangeByIndex(1, 1, 1, 3).merge();

    // Administration
    sheet
        .getRangeByIndex(2, 1)
        .setText('إدارة: ${data.schoolInfo.administration}');
    sheet.getRangeByIndex(2, 1).cellStyle = style;
    sheet.getRangeByIndex(2, 1, 2, 3).merge();

    // School
    sheet.getRangeByIndex(3, 1).setText('مدرسة: ${data.schoolInfo.schoolName}');
    sheet.getRangeByIndex(3, 1).cellStyle = style;
    sheet.getRangeByIndex(3, 1, 3, 3).merge();

    // Class/Grade
    if (isSecondary) {
      // Secondary has special layout
      sheet.getRangeByIndex(2, 22).setText('الصف: ${data.classInfo.grade}');
      sheet.getRangeByIndex(2, 22).cellStyle = style;
      sheet.getRangeByIndex(1, 22).setText('المادة: ${data.classInfo.subject}');
      sheet.getRangeByIndex(1, 22).cellStyle = style;
    } else {
      if (classRow != null && classCol != null) {
        final range = sheet.getRangeByIndex(classRow, classCol);
        range.setText('الصف: ${data.classInfo.className}');
        range.cellStyle = style;
      }
      if (subjectRow != null && subjectCol != null) {
        final range = sheet.getRangeByIndex(subjectRow, subjectCol);
        range.setText('المادة: ${data.classInfo.subject}');
        range.cellStyle = style;
      }
    }
  }

  Style createHeaderStyle(Workbook workbook) {
    const styleName = 'HeaderStyle';
    // Check if style already exists to avoid "Name of style must be unique" error
    if (workbook.styles.contains(styleName)) {
      return workbook.styles[styleName]!;
    }

    final Style style = workbook.styles.add(styleName);
    style.hAlign = HAlignType.center;
    style.vAlign = VAlignType.center;
    style.bold = true;
    style.fontSize = 12;
    style.fontName = 'Noto Kufi Arabic';
    return style;
  }

  Style createDataStyle(Workbook workbook) {
    const styleName = 'DataStyle';
    // Check if style already exists to avoid "Name of style must be unique" error
    if (workbook.styles.contains(styleName)) {
      return workbook.styles[styleName]!;
    }

    final Style style = workbook.styles.add(styleName);
    style.hAlign = HAlignType.center;
    style.vAlign = VAlignType.center;
    style.bold = true;
    style.borders.all.lineStyle = LineStyle.thin;
    style.fontSize = 12;
    style.fontName = 'Noto Kufi Arabic';
    return style;
  }
}

class PrePrimaryExportStrategy extends TemplateStrategy {
  @override
  String get templateName => 'كشف فارغ اعمال السنة اولى وتانية ابتدائى.xlsx';
  @override
  EducationalStage get stage => EducationalStage.prePrimary;
  @override
  ExportType get exportType => ExportType.scores;

  @override
  Future<void> execute(Workbook workbook, ExcelExportEntity data) async {
    final sheet = workbook.worksheets[0];

    fillMetadata(
      sheet,
      data,
      classCol: 12,
      classRow: 3,
      subjectCol: 26,
      subjectRow: 3,
    );

    final startRow = 8;
    final startCol = 3;
    final colsPerWeek = 8;

    final evalIds = [
      'homework_book',
      'classroom_performance',
      'activity_book',
      'weekly_review',
      'oral_tasks',
      'skill_tasks',
      'attendance_and_diligence',
    ];

    final weekStyle = createHeaderStyle(workbook);
    final evalStyle = createHeaderStyle(workbook);

    for (int w = 0; w < 18; w++) {
      final weekNum = w + 1;
      final weekStartColIndex = startCol + (w * colsPerWeek);

      final weekRange = sheet.getRangeByIndex(5, weekStartColIndex + 1);
      final date = data.weekStartDates?[weekNum];
      final dateStr = date != null ? DateFormat('d/M').format(date) : '';
      weekRange.setText('الأسبوع $weekNum $dateStr');
      weekRange.cellStyle = weekStyle;

      final labels = [
        'كراس الواجب',
        'كراس اداء صفى',
        'كراس النشاط',
        'تقييم أسبوعى',
        'مهام شفهية',
        'مهام مهارية',
        'حضور و مواظبة',
      ];
      for (int i = 0; i < labels.length; i++) {
        final cell = sheet.getRangeByIndex(7, weekStartColIndex + 1 + i);
        cell.setText(labels[i]);
        cell.cellStyle = evalStyle;
        cell.columnWidth = 5;
      }
      final totalCell = sheet.getRangeByIndex(7, weekStartColIndex + 8);
      totalCell.setText('المجموع');
      totalCell.cellStyle = evalStyle;
    }

    final avgStartColIndex = startCol + (18 * colsPerWeek);
    final avgTitleRange = sheet.getRangeByIndex(
      5,
      avgStartColIndex + 1,
      5,
      avgStartColIndex + 8,
    );
    avgTitleRange.merge();
    avgTitleRange.setText('متوسط الفصل الدراسي');
    avgTitleRange.cellStyle = weekStyle;

    final avgLabels = [
      'كراس الواجب',
      'كراس اداء صفى',
      'كراس النشاط',
      'تقييم أسبوعى',
      'مهام شفهية',
      'مهام مهارية',
      'حضور و مواظبة',
    ];
    for (int i = 0; i < avgLabels.length; i++) {
      final cell = sheet.getRangeByIndex(7, avgStartColIndex + 1 + i);
      cell.setText(avgLabels[i]);
      cell.cellStyle = evalStyle;
    }
    final avgTotalCell = sheet.getRangeByIndex(7, avgStartColIndex + 8);
    avgTotalCell.setText('المجموع');
    avgTotalCell.cellStyle = evalStyle;

    final dataStyle = createDataStyle(workbook);

    // Calculate active weeks for each evaluation
    final Map<String, int> activeWeeksCount = {};
    for (final evalId in evalIds) {
      int activeWeeks = 0;
      for (int w = 1; w <= 18; w++) {
        bool isWeekActive = false;
        for (final student in data.students) {
          if (student.getScoreForWeek(w, evalId) > 0) {
            isWeekActive = true;
            break;
          }
        }
        if (isWeekActive) {
          activeWeeks++;
        }
      }
      activeWeeksCount[evalId] = activeWeeks;
    }

    for (int i = 0; i < data.students.length; i++) {
      final student = data.students[i];
      final row = startRow + i + 1;

      sheet.getRangeByIndex(row, 3).setText(student.name);
      sheet.getRangeByIndex(row, 3).cellStyle = dataStyle;

      for (int w = 0; w < 18; w++) {
        final weekNum = w + 1;
        final weekStartColIndex = startCol + (w * colsPerWeek);

        for (int e = 0; e < evalIds.length; e++) {
          final score = student.getScoreForWeek(weekNum, evalIds[e]);
          if (score > 0) {
            final range = sheet.getRangeByIndex(row, weekStartColIndex + 1 + e);
            range.setNumber(score.toDouble());
            range.cellStyle = dataStyle;
          }
        }
        final total = student.getTotalForWeek(weekNum);
        if (total > 0) {
          final range = sheet.getRangeByIndex(row, weekStartColIndex + 8);
          range.setNumber(total.toDouble());
          range.cellStyle = dataStyle;
        }
      }

      int studentTotalAverage = 0;
      for (int e = 0; e < evalIds.length; e++) {
        int sum = 0;
        for (int wIdx = 1; wIdx <= 18; wIdx++) {
          final s = student.getScoreForWeek(wIdx, evalIds[e]);
          if (s > 0) {
            sum += s;
          }
        }

        final divisor = activeWeeksCount[evalIds[e]] ?? 0;

        if (divisor > 0) {
          final avg = (sum / divisor).round();
          final range = sheet.getRangeByIndex(row, avgStartColIndex + 1 + e);
          range.setNumber(avg.toDouble());
          range.cellStyle = dataStyle;
          studentTotalAverage += avg;
        }
      }

      if (studentTotalAverage > 0) {
        final range = sheet.getRangeByIndex(row, avgStartColIndex + 8);
        range.setNumber(studentTotalAverage.toDouble());
        range.cellStyle = dataStyle;
      }
    }
  }
}

class PrimaryExportStrategy extends TemplateStrategy {
  @override
  String get templateName => 'كشف فارغ اعمال السنة من 3ل6 ابتدائى.xlsx';
  @override
  EducationalStage get stage => EducationalStage.primary;
  @override
  ExportType get exportType => ExportType.scores;

  @override
  Future<void> execute(Workbook workbook, ExcelExportEntity data) async {
    final sheet = workbook.worksheets[0];

    fillMetadata(
      sheet,
      data,
      classCol: 12,
      classRow: 3,
      subjectCol: 11,
      subjectRow: 3,
    );

    final startRow = 8;
    final startCol = 3;
    final colsPerWeek = 6;

    final evalIds = [
      'primary_homework',
      'primary_activity',
      'primary_weekly',
      'primary_performance',
      'primary_attendance',
    ];
    final labels = [
      'كراس الواجب',
      'كراس النشاط',
      'التقييم الأسبوعي',
      'أداء صفي',
      'مهام و مواظبة',
    ];

    final headerStyle = createHeaderStyle(workbook);
    final dataStyle = createDataStyle(workbook);

    for (int w = 0; w < 18; w++) {
      final weekNum = w + 1;
      final colIndex = startCol + (w * colsPerWeek);

      final cell = sheet.getRangeByIndex(5, colIndex + 1);
      final date = data.weekStartDates?[weekNum];
      final dateStr = date != null ? DateFormat('d/M').format(date) : '';
      cell.setText('الأسبوع $weekNum $dateStr');
      cell.cellStyle = headerStyle;

      for (int i = 0; i < labels.length; i++) {
        final c = sheet.getRangeByIndex(7, colIndex + 1 + i);
        c.setText(labels[i]);
        c.cellStyle = headerStyle;
        c.columnWidth = 20;
      }
      final tc = sheet.getRangeByIndex(7, colIndex + 6);
      tc.setText('المجموع');
      tc.cellStyle = headerStyle;
    }

    final avgStartCol = startCol + (18 * colsPerWeek);
    sheet.getRangeByIndex(5, avgStartCol + 1, 5, avgStartCol + 6).merge();
    sheet.getRangeByIndex(5, avgStartCol + 1).setText('متوسط الفصل الدراسي');
    sheet.getRangeByIndex(5, avgStartCol + 1).cellStyle = headerStyle;

    for (int i = 0; i < labels.length; i++) {
      final c = sheet.getRangeByIndex(7, avgStartCol + 1 + i);
      c.setText(labels[i]);
      c.cellStyle = headerStyle;
    }
    sheet.getRangeByIndex(7, avgStartCol + 6).setText('المجموع');
    sheet.getRangeByIndex(7, avgStartCol + 6).cellStyle = headerStyle;

    final monthStartCol = avgStartCol + colsPerWeek;
    sheet.getRangeByIndex(6, monthStartCol + 1, 6, monthStartCol + 4).merge();
    sheet.getRangeByIndex(6, monthStartCol + 1).setText('اختبارات الشهور');
    sheet.getRangeByIndex(6, monthStartCol + 1).cellStyle = headerStyle;

    final monthLabels = [
      'اختبار مارس',
      'اختبار ابريل',
      'متوسط الاختبارين',
      'ملاحظات',
    ];
    for (int i = 0; i < monthLabels.length; i++) {
      final c = sheet.getRangeByIndex(7, monthStartCol + 1 + i);
      c.setText(monthLabels[i]);
      c.cellStyle = headerStyle;
    }

    // Calculate active weeks for each evaluation
    final Map<String, int> activeWeeksCount = {};
    for (final evalId in evalIds) {
      int activeWeeks = 0;
      for (int w = 1; w <= 18; w++) {
        bool isWeekActive = false;
        for (final student in data.students) {
          if (student.getScoreForWeek(w, evalId) > 0) {
            isWeekActive = true;
            break;
          }
        }
        if (isWeekActive) {
          activeWeeks++;
        }
      }
      activeWeeksCount[evalId] = activeWeeks;
    }

    for (int i = 0; i < data.students.length; i++) {
      final student = data.students[i];
      final row = startRow + i + 1;

      sheet.getRangeByIndex(row, 3).setText(student.name);
      sheet.getRangeByIndex(row, 3).cellStyle = dataStyle;

      for (int w = 0; w < 18; w++) {
        final weekNum = w + 1;
        final baseCol = startCol + (w * colsPerWeek);
        for (int e = 0; e < evalIds.length; e++) {
          final score = student.getScoreForWeek(weekNum, evalIds[e]);
          if (score > 0) {
            final r = sheet.getRangeByIndex(row, baseCol + e + 1);
            r.setNumber(score.toDouble());
            r.cellStyle = dataStyle;
          }
        }
        final tot = student.getTotalForWeek(weekNum);
        if (tot > 0) {
          final r = sheet.getRangeByIndex(row, baseCol + 6);
          r.setNumber(tot.toDouble());
          r.cellStyle = dataStyle;
        }
      }

      int studentTotalAverage = 0;
      for (int e = 0; e < evalIds.length; e++) {
        int sum = 0;
        for (int w = 1; w <= 18; w++) {
          final s = student.getScoreForWeek(w, evalIds[e]);
          if (s > 0) {
            sum += s;
          }
        }

        final divisor = activeWeeksCount[evalIds[e]] ?? 0;

        if (divisor > 0) {
          final avg = (sum / divisor).round();
          final r = sheet.getRangeByIndex(row, avgStartCol + e + 1);
          r.setNumber(avg.toDouble());
          r.cellStyle = dataStyle;
          studentTotalAverage += avg;
        }
      }

      if (studentTotalAverage > 0) {
        final r = sheet.getRangeByIndex(row, avgStartCol + 6);
        r.setNumber(studentTotalAverage.toDouble());
        r.cellStyle = dataStyle;
      }

      final m1 = student.monthlyExamScores?['first_month_exam'] ?? 0;
      final m2 = student.monthlyExamScores?['second_month_exam'] ?? 0;
      final mAvg = student.monthlyExamScores?['months_exam_average'] ?? 0;

      if (m1 > 0) {
        final r = sheet.getRangeByIndex(row, monthStartCol + 1);
        r.setNumber(m1.toDouble());
        r.cellStyle = dataStyle;
      }
      if (m2 > 0) {
        final r = sheet.getRangeByIndex(row, monthStartCol + 2);
        r.setNumber(m2.toDouble());
        r.cellStyle = dataStyle;
      }
      if (mAvg > 0) {
        final r = sheet.getRangeByIndex(row, monthStartCol + 3);
        r.setNumber(mAvg.toDouble());
        r.cellStyle = dataStyle;
      }
    }
  }
}

class PreparatoryExportStrategy extends TemplateStrategy {
  @override
  String get templateName => 'كشف فارغ اعمال السنة اعدادى.xlsx';
  @override
  EducationalStage get stage => EducationalStage.preparatory;
  @override
  ExportType get exportType => ExportType.scores;

  @override
  Future<void> execute(Workbook workbook, ExcelExportEntity data) async {
    final sheet = workbook.worksheets[0];
    fillMetadata(
      sheet,
      data,
      classCol: 12,
      classRow: 3,
      subjectCol: 11,
      subjectRow: 3,
    );

    final startRow = 8;
    final startCol = 3;
    final colsPerWeek = 3;

    final evalIds = [
      'homework_book',
      'weekly_review',
      'attendance_and_diligence',
    ];
    final labels = ['الواجب', 'التقييم الأسبوعي', 'سلوك و مواظبة'];

    final headerStyle = createHeaderStyle(workbook);
    final dataStyle = createDataStyle(workbook);

    for (int w = 0; w < 18; w++) {
      final weekNum = w + 1;
      final col = startCol + (w * colsPerWeek);

      final date = data.weekStartDates?[weekNum];
      final dateStr = date != null ? DateFormat('d/M').format(date) : '';

      final weekTitleRange = sheet.getRangeByIndex(
        6,
        col + 1,
        6,
        col + colsPerWeek,
      );
      weekTitleRange.merge();
      weekTitleRange.setText('الأسبوع $weekNum $dateStr');
      weekTitleRange.cellStyle = headerStyle;

      for (int i = 0; i < labels.length; i++) {
        final c = sheet.getRangeByIndex(7, col + 1 + i);
        c.setText(labels[i]);
        c.cellStyle = headerStyle;
        c.columnWidth = 15;
      }
    }

    final avgStartCol = startCol + (18 * colsPerWeek);
    sheet
        .getRangeByIndex(6, avgStartCol + 1, 6, avgStartCol + labels.length)
        .merge();
    final avgTitle = sheet.getRangeByIndex(6, avgStartCol + 1);
    avgTitle.setText('متوسط الفصل الدراسي');
    avgTitle.cellStyle = headerStyle;

    for (int i = 0; i < labels.length; i++) {
      final c = sheet.getRangeByIndex(7, avgStartCol + 1 + i);
      c.setText(labels[i]);
      c.cellStyle = headerStyle;
    }

    final monthStartCol = avgStartCol + labels.length;
    sheet.getRangeByIndex(6, monthStartCol + 1, 6, monthStartCol + 4).merge();
    sheet.getRangeByIndex(6, monthStartCol + 1).setText('اختبارات الشهور');
    sheet.getRangeByIndex(6, monthStartCol + 1).cellStyle = headerStyle;

    final monthLabels = [
      'اختبار مارس',
      'اختبار ابريل',
      'متوسط الاختبارين',
      'ملاحظات',
    ];
    for (int i = 0; i < monthLabels.length; i++) {
      final c = sheet.getRangeByIndex(7, monthStartCol + 1 + i);
      c.setText(monthLabels[i]);
      c.cellStyle = headerStyle;
    }

    // Calculate active weeks for each evaluation
    final Map<String, int> activeWeeksCount = {};
    for (final evalId in evalIds) {
      int activeWeeks = 0;
      for (int w = 1; w <= 18; w++) {
        bool isWeekActive = false;
        for (final student in data.students) {
          if (student.getScoreForWeek(w, evalId) > 0) {
            isWeekActive = true;
            break;
          }
        }
        if (isWeekActive) {
          activeWeeks++;
        }
      }
      activeWeeksCount[evalId] = activeWeeks;
    }

    for (int i = 0; i < data.students.length; i++) {
      final student = data.students[i];
      final row = startRow + i + 1;

      sheet.getRangeByIndex(row, 3).setText(student.name);
      sheet.getRangeByIndex(row, 3).cellStyle = dataStyle;

      for (int w = 0; w < 18; w++) {
        final weekNum = w + 1;
        final baseCol = startCol + (w * colsPerWeek);
        for (int e = 0; e < evalIds.length; e++) {
          final score = student.getScoreForWeek(weekNum, evalIds[e]);
          if (score > 0) {
            final r = sheet.getRangeByIndex(row, baseCol + e + 1);
            r.setNumber(score.toDouble());
            r.cellStyle = dataStyle;
          }
        }
      }

      for (int e = 0; e < evalIds.length; e++) {
        int sum = 0;
        for (int w = 1; w <= 18; w++) {
          final s = student.getScoreForWeek(w, evalIds[e]);
          if (s > 0) {
            sum += s;
          }
        }

        final divisor = activeWeeksCount[evalIds[e]] ?? 0;

        if (divisor > 0) {
          final r = sheet.getRangeByIndex(row, avgStartCol + e + 1);
          r.setNumber((sum / divisor).roundToDouble());
          r.cellStyle = dataStyle;
        }
      }

      final m1 = student.monthlyExamScores?['first_month_exam'] ?? 0;
      final m2 = student.monthlyExamScores?['second_month_exam'] ?? 0;
      final mAvg = student.monthlyExamScores?['months_exam_average'] ?? 0;

      if (m1 > 0) {
        final r = sheet.getRangeByIndex(row, monthStartCol + 1);
        r.setNumber(m1.toDouble());
        r.cellStyle = dataStyle;
      }
      if (m2 > 0) {
        final r = sheet.getRangeByIndex(row, monthStartCol + 2);
        r.setNumber(m2.toDouble());
        r.cellStyle = dataStyle;
      }
      if (mAvg > 0) {
        final r = sheet.getRangeByIndex(row, monthStartCol + 3);
        r.setNumber(mAvg.toDouble());
        r.cellStyle = dataStyle;
      }
    }
  }
}

class SecondaryExportStrategy extends TemplateStrategy {
  @override
  String get templateName => 'كشف فارغ اعمال السنة ثانوى نظام شهور.xlsx';
  @override
  EducationalStage get stage => EducationalStage.secondary;
  @override
  ExportType get exportType => ExportType.scores;

  @override
  Future<void> execute(Workbook workbook, ExcelExportEntity data) async {
    final sheet = workbook.worksheets[0];

    // 1. Fill Metadata
    fillMetadata(
      sheet,
      data,
      isSecondary: true,
      subjectCol: 2, // Moved from 22 to 2 (below Name) or custom
      subjectRow: 1,
      classCol: 2,
      classRow: 2,
    );

    final headerStyle = createHeaderStyle(workbook);
    final dataStyle = createDataStyle(workbook);

    // 2. Build Headers
    _buildHeaders(sheet, headerStyle);

    // 3. Fill Student Data
    final startRow = 8;

    // Column Mapping:
    // Serial: 1, Name: 2
    // Month 1: 3-10
    // Month 2: 11-18
    // Month 3: 19-26
    // Semester Summary: 27-31

    for (int i = 0; i < data.students.length; i++) {
      final student = data.students[i];
      final row = startRow + i;

      // Serial & Name
      sheet.getRangeByIndex(row, 1).setNumber((i + 1).toDouble());
      sheet.getRangeByIndex(row, 1).cellStyle = dataStyle;

      sheet.getRangeByIndex(row, 2).setText(student.name);
      sheet.getRangeByIndex(row, 2).cellStyle = dataStyle;

      double totalThreeMonths = 0;

      // Iterate 3 Months
      for (int m = 1; m <= 3; m++) {
        final startCol = 3 + (m - 1) * 8;

        // 1. Behavior (Max 10)
        // Key: attendance_and_diligence (from app_values.dart)
        // We need to fetch this. Is it weekly or monthly?
        // In secondary, it's usually per month or accumulated.
        // For now, let's assume we sum weekly scores for the month or take an average?
        // Metadata says "Secondary Evaluation Scores" has "attendance_and_diligence": 10
        // Let's sum weekly 'attendance_and_diligence' for the 4 weeks of this month?
        // Or is it a single entry for the month?
        // Standard practice: Sum of 4 weeks or specific entry.
        // Let's implement Sum of 4 weeks for now.

        final baseWeek = (m - 1) * 4 + 1;

        // Assessments (Weekly Reviews)
        double assessmentSum = 0;
        int assessmentCount = 0;

        // Behavior & Attendance
        double behaviorSum = 0;
        int behaviorCount = 0;

        // Homework
        double homeworkSum = 0;
        int homeworkCount = 0;

        for (int w = 0; w < 4; w++) {
          final weekNum = baseWeek + w;

          // Behavior
          if (student.weeklyScores[weekNum]?.containsKey(
                'attendance_and_diligence',
              ) ??
              false) {
            final b = student.getScoreForWeek(
              weekNum,
              'attendance_and_diligence',
            );
            behaviorSum += b;
            behaviorCount++;
          }

          // Homework
          if (student.weeklyScores[weekNum]?.containsKey('homework_book') ??
              false) {
            final h = student.getScoreForWeek(weekNum, 'homework_book');
            homeworkSum += h;
            homeworkCount++;
          }

          // Assessment
          final a = student.getScoreForWeek(weekNum, 'weekly_review');
          // For assessments, usually valid > 0 or if key exists?
          // Previous logic checked (a > 0).
          // But if student got 0, it should count?
          // Let's check key existence.
          if (student.weeklyScores[weekNum]?.containsKey('weekly_review') ??
              false) {
            assessmentSum += a;
            assessmentCount++;

            // Write Assessment Score only if > 0 or if we want to show 0?
            // Usually we show what is there.
            if (a > 0) {
              final assessCol = startCol + 2 + w;
              final cell = sheet.getRangeByIndex(row, assessCol);
              cell.setNumber(a.toDouble());
              cell.cellStyle = dataStyle;
            }
          }
        }

        // Calculate Averages for Month
        final behaviorAvg = behaviorCount > 0
            ? (behaviorSum / behaviorCount)
            : 0.0;
        final homeworkAvg = homeworkCount > 0
            ? (homeworkSum / homeworkCount)
            : 0.0;

        // Write Behavior (Col 1 of Month)
        final behaviorCell = sheet.getRangeByIndex(row, startCol);
        behaviorCell.setNumber(behaviorAvg.toDouble());
        behaviorCell.cellStyle = dataStyle;

        // Write Homework (Col 2 of Month)
        final homeworkCell = sheet.getRangeByIndex(row, startCol + 1);
        homeworkCell.setNumber(homeworkAvg.toDouble());
        homeworkCell.cellStyle = dataStyle;

        // Calculate Assessment Avg (Col 7 of Month)
        double assessmentAvg = 0;
        if (assessmentCount > 0) {
          assessmentAvg = assessmentSum / assessmentCount;
        }
        final avgCell = sheet.getRangeByIndex(row, startCol + 6);
        avgCell.setNumber(assessmentAvg);
        avgCell.cellStyle = dataStyle;

        // Month Total (Col 8 of Month)
        // Behavior + Homework + AssessmentAvg
        final monthTotal = behaviorAvg + homeworkAvg + assessmentAvg;
        final totalCell = sheet.getRangeByIndex(row, startCol + 7);
        totalCell.setNumber(monthTotal);
        totalCell.cellStyle = dataStyle;

        totalThreeMonths += monthTotal;
      }

      // Semester Summary
      final semStartCol = 27;

      // 1. Total 3 Months
      final total3MonthsCell = sheet.getRangeByIndex(row, semStartCol);
      total3MonthsCell.setNumber(totalThreeMonths); // Max 120
      total3MonthsCell.cellStyle = dataStyle;

      // 2. Average 3 Months
      final avg3Months = totalThreeMonths / 3;
      final avg3MonthsCell = sheet.getRangeByIndex(row, semStartCol + 1);
      avg3MonthsCell.setNumber(avg3Months); // Max 40
      avg3MonthsCell.cellStyle = dataStyle;

      // 3. Exam 1
      final exam1 = (student.monthlyExamScores?['first_month_exam'] ?? 0)
          .toDouble();
      final exam1Cell = sheet.getRangeByIndex(row, semStartCol + 2);
      exam1Cell.setNumber(exam1);
      exam1Cell.cellStyle = dataStyle;

      // 4. Exam 2
      final exam2 = (student.monthlyExamScores?['second_month_exam'] ?? 0)
          .toDouble();
      final exam2Cell = sheet.getRangeByIndex(row, semStartCol + 3);
      exam2Cell.setNumber(exam2);
      exam2Cell.cellStyle = dataStyle;

      // 5. Grand Total (Work Year)
      final grandTotal = avg3Months + exam1 + exam2;
      final grandTotalCell = sheet.getRangeByIndex(row, semStartCol + 4);
      grandTotalCell.setNumber(grandTotal); // Max 70
      grandTotalCell.cellStyle = dataStyle;
    }
  }

  void _buildHeaders(Worksheet sheet, Style headerStyle) {
    // 1. Month Headers
    final monthNames = [
      'شهر فبراير 2026م',
      'شهر مارس 2026م',
      'شهر ابريل 2026م',
    ];
    for (int m = 0; m < 3; m++) {
      final startCol = 3 + (m * 8);
      final range = sheet.getRangeByIndex(5, startCol, 5, startCol + 7);
      range.merge();
      range.setText(monthNames[m]);
      range.cellStyle = headerStyle;

      // Sub-Headers Row 6
      // "Weekly Assessments" covers Col 3, 4, 5, 6 of the month block
      final assessRange = sheet.getRangeByIndex(
        6,
        startCol + 2,
        6,
        startCol + 5,
      );
      assessRange.merge();
      assessRange.setText('التقييمات الأسبوعية');
      assessRange.cellStyle = headerStyle;

      // Row 6 Vertical merges for others?
      // Behavior, Homework, Avg, Total -> Merge Row 6 & 7?
      // Usually yes for clean layout.

      // Headers Row 7 (Leafs)
      final labels = [
        'سلوك ومواظبة',
        'كشكول الحصة والواجب',
        'الأسبوع الأول',
        'الأسبوع الثاني',
        'الأسبوع الثالث',
        'الأسبوع الرابع',
        'متوسط التقييمات',
        'المجموع',
      ];

      for (int i = 0; i < labels.length; i++) {
        final cell = sheet.getRangeByIndex(7, startCol + i);
        cell.setText(labels[i]);
        cell.cellStyle = headerStyle;
        cell.columnWidth = 10; // Adjust width
      }
    }

    // 2. Semester Summary Headers
    final semStartCol = 27;
    final semLabels = [
      'مجموع الشهور الثلاثة',
      'متوسط الشهور الثلاثة',
      'امتحان الشهر الأول',
      'امتحان الشهر الثاني',
      'مجموع اعمال السنة',
    ];

    // Merge Row 5&6 for these?
    for (int i = 0; i < semLabels.length; i++) {
      final col = semStartCol + i;
      final range = sheet.getRangeByIndex(5, col, 6, col); // Merge top
      range.merge();
      range.setText(
        semLabels[i],
      ); // Actually put text in Row 7 for simple layout?
      // Usually Header is bottom aligned. Let's put text in 7.
      // Or merge 5,6,7?
      // Let's stick to putting text in 7 and merging above if needed.
      // Actually user image shows text rotated or wrapped.
      // For simplicity, we just set checking Row 7.

      sheet.getRangeByIndex(5, col).setText(semLabels[i]);
      sheet.getRangeByIndex(5, col).cellStyle = headerStyle;
      // Reset merge if needed, but text up top is fine.
    }

    // Serial & Name
    sheet.getRangeByIndex(5, 1, 7, 1).merge(); // Merge 3 rows
    sheet.getRangeByIndex(5, 1).setText('م');
    sheet.getRangeByIndex(5, 1).cellStyle = headerStyle;

    sheet.getRangeByIndex(5, 2, 7, 2).merge();
    sheet.getRangeByIndex(5, 2).setText('الاسم');
    sheet.getRangeByIndex(5, 2).cellStyle = headerStyle;
    sheet.getRangeByIndex(5, 2).columnWidth = 25;
  }
}

class AttendanceExportStrategy extends TemplateStrategy {
  @override
  String get templateName => 'attendance_sheet.xlsx';
  @override
  EducationalStage get stage => EducationalStage.primary; // Or default
  @override
  ExportType get exportType => ExportType.attendance;

  @override
  Future<void> execute(Workbook workbook, ExcelExportEntity data) async {
    final sheet = workbook.worksheets[0];
    fillMetadata(
      sheet,
      data,
      classCol: 11,
      classRow: 3,
      subjectCol: 3,
      subjectRow: 3,
    );

    final startRow = 6;
    final startCol = 3;
    final colsPerWeek = 6;

    final headerStyle = createHeaderStyle(workbook);
    final dataStyle = createDataStyle(workbook);

    final weeks = List.generate(
      data.weekStartDates?.length ?? 18,
      (i) => i + 1,
    );

    // Serial and Name headers
    final serialHeader = sheet.getRangeByIndex(5, 2, 6, 2);
    serialHeader.merge();
    serialHeader.setText('م');
    serialHeader.cellStyle = headerStyle;
    serialHeader.cellStyle.borders.all.lineStyle = LineStyle.thin;

    final nameHeader = sheet.getRangeByIndex(5, 3, 6, 3);
    nameHeader.merge();
    nameHeader.setText('الاسم');
    nameHeader.cellStyle = headerStyle;
    nameHeader.cellStyle.borders.all.lineStyle = LineStyle.thin;
    sheet.getRangeByIndex(5, 3).columnWidth = 25;

    for (int w = 0; w < weeks.length; w++) {
      final weekNum = weeks[w];
      final colIndex = startCol + (w * colsPerWeek);

      final weekRange = sheet.getRangeByIndex(5, colIndex + 1, 5, colIndex + 6);
      weekRange.merge();
      final date = data.weekStartDates?[weekNum];
      final dateStr = date != null ? DateFormat('d/M').format(date) : '';
      weekRange.setText('الأسبوع $weekNum $dateStr');
      weekRange.cellStyle = headerStyle;
      weekRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      final days = [
        'السبت',
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
      ];
      for (int d = 0; d < days.length; d++) {
        final c = sheet.getRangeByIndex(6, colIndex + 1 + d);
        c.setText(days[d]);
        c.cellStyle = headerStyle;
        c.cellStyle.borders.all.lineStyle = LineStyle.thin;
        c.columnWidth = 5;
      }
    }

    for (int i = 0; i < data.students.length; i++) {
      final student = data.students[i];
      final row = startRow + i + 1;

      sheet.getRangeByIndex(row, 2).setNumber((i + 1).toDouble());
      sheet.getRangeByIndex(row, 2).cellStyle = dataStyle;

      sheet.getRangeByIndex(row, 3).setText(student.name);
      sheet.getRangeByIndex(row, 3).cellStyle = dataStyle;

      if (student.weeklyAttendance != null) {
        for (int w = 0; w < weeks.length; w++) {
          final weekNum = weeks[w];
          final colIndex = startCol + (w * colsPerWeek);

          final weekAtt = student.weeklyAttendance![weekNum];
          if (weekAtt != null) {
            final startDate = data.weekStartDates?[weekNum];
            if (startDate != null) {
              for (int d = 0; d < 6; d++) {
                final dayDate = startDate.add(Duration(days: d));
                final normalized = DateTime(
                  dayDate.year,
                  dayDate.month,
                  dayDate.day,
                );
                final status = weekAtt[normalized];

                String statusText = '';
                if (status == AttendanceStatus.present) {
                  statusText = 'ح';
                } else if (status == AttendanceStatus.absent) {
                  statusText = 'غ';
                } else if (status == AttendanceStatus.excused) {
                  statusText = 'ع';
                }

                if (statusText.isNotEmpty) {
                  final r = sheet.getRangeByIndex(row, colIndex + 1 + d);
                  r.setText(statusText);
                  r.cellStyle = dataStyle;
                }
              }
            }
          }
        }
      }
    }
  }
}
