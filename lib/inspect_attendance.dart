import 'dart:io';

import 'package:excel/excel.dart';

void main() {
  final file = File(
    r'c:\Users\Lenovo\moalem-app\assets\files\كشف فارغ الغياب.xlsx',
  );
  if (!file.existsSync()) {
    print('File not found at ${file.path}');
    return;
  }

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  for (final table in excel.tables.keys) {
    print('--- Sheet: $table ---');
    final sheet = excel.tables[table]!;

    // Print rows 3-10 to find headers
    for (var row = 3; row <= 10; row++) {
      final rowData = <String>[];
      for (var col = 0; col < 50; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        final value = cell.value?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          print('Row $row, Col $col: $value');
        }
        rowData.add(value.isEmpty ? '.' : value);
      }
      // print('Row $row: $rowData'); // too verbose, rely on specific cells
    }
  }
}
