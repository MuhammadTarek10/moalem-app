import 'dart:io';
import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
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

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
          build: (context) => [
            // Header with metadata
            _buildHeader(printData),
            pw.SizedBox(height: 20),

            // Student data table
            _buildDataTable(printData),
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
            'تقرير ${printData.printType == PrintType.scores ? 'الدرجات' : 'الحضور'}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          _buildMetadataRow('المحافظة', printData.governorate),
          _buildMetadataRow('الإدارة التعليمية', printData.administration),
          _buildMetadataRow('المدرسة', printData.classEntity.school),
          _buildMetadataRow('الفصل', printData.classEntity.name),
          _buildMetadataRow('المادة', printData.classEntity.subject),
          _buildMetadataRow('الفترة', 'الأسبوع ${printData.periodNumber}'),
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
      headers.add('الحالة');
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
        final attendanceData = studentData.attendance ?? {};
        final status = attendanceData.values.isNotEmpty
            ? _getAttendanceStatusText(attendanceData.values.first)
            : '-';
        row.add(status);
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
