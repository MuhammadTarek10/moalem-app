import 'dart:io';

import 'package:excel/excel.dart';

void main() {
  final file = File('assets/files/كشف فارغ اعمال السنة اعدادى.xlsx');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  for (final table in excel.tables.keys) {
    print('--- Check Sheet: $table ---');
    final sheet = excel.tables[table]!;

    // Check Rows 4 to 9 (Indices 3 to 8)
    for (var r = 3; r <= 8; r++) {
      if (r >= sheet.rows.length) break;

      final rowData = sheet.rows[r];
      print('--- Row $r (Excel Row ${r + 1}) ---');
      for (var c = 0; c < rowData.length; c++) {
        final cell = rowData[c];
        if (cell != null && cell.value != null) {
          final val = cell.value.toString().trim();
          if (val.isNotEmpty) {
            print('  Col $c (${getColName(c)}): "$val"');
          }
        }
      }
    }
  }
}

String getColName(int colIndex) {
  // Simple A-Z converter for debugging
  if (colIndex < 26) return String.fromCharCode(65 + colIndex);
  return 'AA+';
}
