import 'dart:io';

import 'package:excel/excel.dart';

void main() async {
  // Check attendance_sheet.xlsx
  final path =
      'c:\\Users\\Lenovo\\moalem-app\\assets\\files\\attendance_sheet.xlsx';
  final file = File(path);
  if (!file.existsSync()) {
    print('File not found at $path');
    return;
  }

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  final sheetName = excel.tables.keys.first;
  final sheet = excel.tables[sheetName]!;

  print('Sheet: $sheetName');
  // print('Max Cols: ${sheet.maxCols}, Max Rows: ${sheet.maxRows}');

  // Check Headers (Rows 4, 5, 6, 7)
  for (int row = 3; row < 10; row++) {
    print('--- Row ${row + 1} (Index $row) ---');
    for (int col = 0; col < 10; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      final val = cell.value;
      if (val != null) {
        print('  Col $col (Index $col): $val');
      }
    }
  }
}
