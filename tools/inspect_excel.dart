import 'dart:io';

import 'package:excel/excel.dart';

void main() async {
  final file = File('assets/files/كشف فارغ اعمال السنة من 3ل6 ابتدائى.xlsx');

  if (!await file.exists()) {
    print('File not found: ${file.path}');
    return;
  }

  final bytes = await file.readAsBytes();
  final excel = Excel.decodeBytes(bytes);

  for (final table in excel.tables.keys) {
    print('Sheet: $table');
    final sheet = excel.tables[table];
    if (sheet == null) continue;

    // Print first 10 rows to find headers
    for (var i = 0; i < 10; i++) {
      if (i >= sheet.maxRows) break;

      final row = sheet.rows[i];
      final rowData = row.map((cell) => cell?.value?.toString() ?? '').toList();
      print('Row $i: $rowData');
    }
  }
}
