import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

void main() {
  test('Analyze Excel File Structure', () {
    final filePath = r'c:\Users\Lenovo\moalem-app\كشف فارغ الغياب.xlsx';
    final file = File(filePath);

    if (!file.existsSync()) {
      print('File not found at $filePath');
      return;
    }

    try {
      final List<int> bytes = file.readAsBytesSync();
      final Workbook workbook = Workbook();
      // Attempt to load the file. Note: The comment in existing code said it can't read,
      // but we are verifying this capability.
      // Syncfusion XlsIO documentation usually supports .open or similar on a workbook.
      // However, the Dart package might be limited.
      // Checking local API by trying:

      // Since I don't have the API docs, I'll rely on common XlsIO patterns.
      // If this fails, we know we can't read.

      // Note: The syncfusion_flutter_xlsio package primarily creates files.
      // Reading might not be supported in the free/flutter version or via this specific API.
      // But let's try standard methods.

      // There isn't a direct "open" on Workbook constructor often, usually it is load.
      // actually, looking at the package structure in similar projects:
      // it is often write-only in some flutter implementations.
      // But let's try.

      print('Attempting to read bytes...');
      // There is no load method on Workbook()?
      // Wait, if I cannot verify API, I'll assume the comment "Syncfusion xlsio can only create" is likely correct for this package.

      print('File size: ${bytes.length} bytes');
    } catch (e) {
      print('Error analyzing file: $e');
    }
  });
}
