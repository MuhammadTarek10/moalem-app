import 'dart:io';
import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Service to export print data to PDF
@injectable
class PdfExportService {
  /// Export print data to PDF file (async but non-blocking)
  Future<String> exportToPdf(PrintDataEntity printData) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Load Arabic font for RTL support
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      // Yield to UI thread
      await Future.delayed(Duration.zero);

      // Use landscape for multi-week (many columns)
      final pageFormat = printData.isMultiWeek
          ? PdfPageFormat.a4.landscape
          : PdfPageFormat.a4;

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
          build: (context) => [
            // Header with metadata
            _buildHeader(printData),
            pw.SizedBox(height: 20),

            // Student data table
            printData.isMultiWeek
                ? _buildMultiWeekDataTable(printData)
                : _buildDataTable(printData),
          ],
        ),
      );

      // Yield to UI thread
      await Future.delayed(Duration.zero);

      // Save the file
      final filePath = await _savePdfFile(pdf, printData);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  /// Build PDF header with metadata
  pw.Widget _buildHeader(PrintDataEntity printData) {
    // Determine period text
    String? periodText;
    String? periodLabel;

    if (!printData.isMultiWeek &&
        printData.printType == PrintType.attendance &&
        printData.weekStartDate != null) {
      final dateFormat = DateFormat('d/M/yyyy', 'ar');
      periodText =
          '${dateFormat.format(printData.weekStartDate!)} - ${dateFormat.format(printData.weekEndDate!)}';
      periodLabel = 'الأسبوع';
    } else if (!printData.isMultiWeek) {
      periodText = 'الأسبوع ${printData.periodNumber}';
      periodLabel = 'الأسبوع';
    }

    String titleText;
    if (printData.isMultiWeek) {
      titleText = printData.printType == PrintType.scores
          ? 'سجل رصد درجات فصل'
          : 'سجل الحضور والغياب';
    } else {
      titleText =
          'تقرير ${printData.printType == PrintType.scores ? 'الدرجات' : 'الحضور'}';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titleText,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          _buildMetadataRow('المحافظة/', printData.governorate),
          _buildMetadataRow('الإدارة التعليمية/', printData.administration),
          _buildMetadataRow('المدرسة/', printData.classEntity.school),
          _buildMetadataRow('الفصل/', printData.classEntity.name),
          _buildMetadataRow('المادة/', printData.classEntity.subject),
          if (periodLabel != null && periodText != null)
            _buildMetadataRow(periodLabel, periodText),
        ],
      ),
    );
  }

  /// Build metadata row
  pw.Widget _buildMetadataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(value, textDirection: pw.TextDirection.rtl),
          ),
        ],
      ),
    );
  }

  /// Build data table with RTL support (columns reversed)
  pw.Widget _buildDataTable(PrintDataEntity printData) {
    // Prepare headers in RTL order (right to left)
    final headers = <String>[];

    if (printData.printType == PrintType.scores &&
        printData.evaluations != null) {
      headers.add('المجموع');
      // Add evaluation headers in reverse
      for (var i = printData.evaluations!.length - 1; i >= 0; i--) {
        headers.add(_getEvaluationShortName(printData.evaluations![i].name));
      }
    } else if (printData.printType == PrintType.attendance) {
      // Weekly attendance with day columns (Sat-Thu)
      if (printData.weekStartDate != null) {
        final weekDays = printData.weekDays;
        final dateFormat = DateFormat('d/M', 'ar');

        // Add days in reverse for RTL
        for (var i = weekDays.length - 1; i >= 0; i--) {
          final day = weekDays[i];
          final dayName = WeekHelper.getShortDayNameArabic(day.weekday);
          headers.add('$dayName ${dateFormat.format(day)}');
        }
      } else {
        headers.add('الحالة');
      }
    }

    // Add name and number at the end (they'll appear on the right in RTL)
    headers.add('اسم الطالب');
    headers.add('رقم الطالب');

    // Prepare data rows in RTL order
    final rows = <List<dynamic>>[];
    for (final studentData in printData.studentsData) {
      final row = <dynamic>[];

      if (printData.printType == PrintType.scores &&
          printData.evaluations != null) {
        // Add total first (rightmost)
        row.add('${studentData.totalScore}/${studentData.maxPossibleScore}');

        // Add scores in reverse
        for (var i = printData.evaluations!.length - 1; i >= 0; i--) {
          final evaluation = printData.evaluations![i];
          final score = studentData.scores[evaluation.id] ?? 0;
          row.add('$score/${evaluation.maxScore}');
        }
      } else if (printData.printType == PrintType.attendance) {
        // Weekly attendance with day columns (Sat-Thu)
        if (printData.weekStartDate != null &&
            studentData.attendanceDaily != null) {
          final weekDays = printData.weekDays;

          // Add days in reverse for RTL
          for (var i = weekDays.length - 1; i >= 0; i--) {
            final day = weekDays[i];
            final status = studentData.getAttendanceForDate(day);
            row.add(status != null ? _getAttendanceStatusSymbol(status) : '-');
          }
        } else {
          final attendanceData = studentData.attendance ?? {};
          final status = attendanceData.values.isNotEmpty
              ? _getAttendanceStatusText(attendanceData.values.first)
              : '-';
          row.add(status);
        }
      }

      // Add name and number at the end (rightmost in display)
      row.add(studentData.student.name);
      row.add(studentData.student.number);

      rows.add(row);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple),
      cellHeight: 30,
      cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerRight},
      headerAlignments: {0: pw.Alignment.center, 1: pw.Alignment.center},
    );
  }

  /// Build multi-week data table with all weeks
  pw.Widget _buildMultiWeekDataTable(PrintDataEntity printData) {
    final weekNumbers = printData.weekNumbers;
    final fontSize = weekNumbers.length > 15
        ? 4.5
        : (weekNumbers.length > 5 ? 5.5 : 8.0);
    final dateFormat = DateFormat('d/M', 'ar');
    final dayNames = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس'];

    // Determine columns per week based on print type
    int colsPerWeek;
    if (printData.printType == PrintType.scores &&
        printData.evaluations != null) {
      colsPerWeek = printData.evaluations!.length + 1; // evaluations + total
    } else if (printData.printType == PrintType.attendance) {
      colsPerWeek = 6; // 6 days (Sat-Thu)
    } else {
      return pw.Text('لا توجد بيانات');
    }

    // Calculate total columns
    final numDataCols = weekNumbers.length * colsPerWeek;
    final totalCols = 2 + numDataCols; // م + الاسم + data columns

    // Prepare all headers in one row (simplified for RTL)
    final headers = <String>[];

    // Add week columns in reverse for RTL (rightmost first in list = leftmost in RTL display)
    for (var w = weekNumbers.length - 1; w >= 0; w--) {
      final weekNum = weekNumbers[w];
      final weekStartDate = printData.weekStartDates?[weekNum];
      final weekLabel = weekStartDate != null
          ? 'أسبوع ${_getArabicOrdinal(weekNum)} ${dateFormat.format(weekStartDate)}'
          : 'الأسبوع ${_getArabicOrdinal(weekNum)}';

      if (printData.printType == PrintType.scores &&
          printData.evaluations != null) {
        // Add total first (rightmost for this week)
        headers.add('$weekLabel\nالمجموع');

        // Add evaluations in reverse
        final evaluations = printData.evaluations!;
        for (var e = evaluations.length - 1; e >= 0; e--) {
          headers.add(
            '$weekLabel\n${_getEvaluationShortName(evaluations[e].name)}',
          );
        }
      } else if (printData.printType == PrintType.attendance) {
        // Add days in reverse for RTL (Thu first, then Wed, etc.)
        final weekDays = weekStartDate != null
            ? WeekHelper.getWeekDays(weekStartDate)
            : <DateTime>[];
        for (var d = 5; d >= 0; d--) {
          if (weekDays.isNotEmpty && d < weekDays.length) {
            headers.add(
              '$weekLabel\n${dayNames[d]} ${dateFormat.format(weekDays[d])}',
            );
          } else {
            headers.add('$weekLabel\n${dayNames[d]}');
          }
        }
      }
    }

    // Add name and number at the end (rightmost in RTL display)
    headers.add('الاسم');
    headers.add('م');

    // Prepare data rows
    final rows = <List<dynamic>>[];
    for (final studentData in printData.studentsData) {
      final row = <dynamic>[];

      // Add week data in reverse for RTL
      for (var w = weekNumbers.length - 1; w >= 0; w--) {
        final weekNum = weekNumbers[w];

        if (printData.printType == PrintType.scores &&
            printData.evaluations != null) {
          // Add total first
          row.add(studentData.getTotalForWeek(weekNum).toString());

          // Add evaluations in reverse
          final evaluations = printData.evaluations!;
          for (var e = evaluations.length - 1; e >= 0; e--) {
            final evaluation = evaluations[e];
            final score = studentData.getScoreForWeek(weekNum, evaluation.id);
            row.add(score.toString());
          }
        } else if (printData.printType == PrintType.attendance) {
          // Add days in reverse for RTL
          final weekStartDate = printData.weekStartDates?[weekNum];
          final weekDays = weekStartDate != null
              ? WeekHelper.getWeekDays(weekStartDate)
              : <DateTime>[];

          for (var d = 5; d >= 0; d--) {
            if (weekDays.isNotEmpty && d < weekDays.length) {
              final day = weekDays[d];
              final status = studentData.getAttendanceForWeekDate(weekNum, day);
              row.add(
                status != null ? _getAttendanceStatusSymbol(status) : '-',
              );
            } else {
              row.add('-');
            }
          }
        }
      }

      // Add name and number
      row.add(studentData.student.name);
      row.add(studentData.student.number.toString());

      rows.add(row);
    }

    // Build alignments map
    final cellAlignments = <int, pw.Alignment>{};
    final headerAlignments = <int, pw.Alignment>{};
    for (var i = 0; i < totalCols; i++) {
      cellAlignments[i] = pw.Alignment.center;
      headerAlignments[i] = pw.Alignment.center;
    }
    // Name column should be right-aligned
    cellAlignments[totalCols - 2] = pw.Alignment.centerRight;

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: fontSize,
      ),
      cellStyle: pw.TextStyle(fontSize: fontSize),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellHeight: 25,
      cellAlignments: cellAlignments,
      headerAlignments: headerAlignments,
    );
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

  /// Get attendance status text in Arabic
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

  /// Get evaluation short name in Arabic
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

  /// Save PDF file to device
  Future<String> _savePdfFile(
    pw.Document pdf,
    PrintDataEntity printData,
  ) async {
    try {
      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final typePrefix = printData.printType == PrintType.scores
          ? 'scores'
          : 'attendance';
      final className = printData.classEntity.name.replaceAll('/', '_');
      final filename = '${typePrefix}_${className}_$timestamp.pdf';

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';

      // Save PDF
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: filename,
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );

      return filePath;
    } catch (e) {
      throw Exception('Failed to save PDF file: $e');
    }
  }
}
