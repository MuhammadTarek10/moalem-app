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

    // Max students per page (4 rows * 3 columns = 12)
    const int maxPerPage = 12;

    for (var i = 0; i < students.length; i += maxPerPage) {
      final subList = students.sublist(
        i,
        (i + maxPerPage) > students.length ? students.length : (i + maxPerPage),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(
            20,
          ), // Reduced margins (approx 0.7 cm)
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
          build: (context) {
            return pw.Column(
              children: [
                pw.Text(
                  'طباعة الكيو آر كود للطلاب',
                  style: pw.TextStyle(
                    fontSize: 16, // Smaller header to save space
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 3,
                    childAspectRatio:
                        0.9, // Optimised for 3x4 on A4 with small margins
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: subList.map((student) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 2,
                          ),
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Expanded(
                              child: pw.Center(
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: student.qrCode,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              student.name,
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                              overflow: pw.TextOverflow.clip,
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.SizedBox(height: 5),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Text(
                                '${student.number}',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
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
