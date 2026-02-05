import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

@injectable
class QrPdfService {
  Future<void> generateAndPrintQrCodes(List<StudentEntity> students) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    // Max students per page
    const int maxPerPage = 50;

    for (var i = 0; i < students.length; i += maxPerPage) {
      final subList = students.sublist(
        i,
        (i + maxPerPage) > students.length ? students.length : (i + maxPerPage),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
          build: (context) {
            return pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'طباعة الكيو آر كود للطلاب',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 5,
                    childAspectRatio: 0.8,
                    children: subList.map((student) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: student.qrCode,
                              width: 60,
                              height: 60,
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              student.name,
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                            ),
                            pw.Text(
                              'ID: ${student.number}',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey700,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Save and Share
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'student_qrs_$timestamp.pdf';
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(filePath)], subject: 'Student QR Codes');
  }
}
