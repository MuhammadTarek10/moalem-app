import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

void main() async {
  final file = File(
    r'c:\Users\Lenovo\moalem-app\assets\files\كشف فارغ اعمال السنة اولى وتانية ابتدائى.xlsx',
  );
  final bytes = await file.readAsBytes();

  // Try to decode, if it fails, patch and retry
  Excel excel;
  try {
    excel = Excel.decodeBytes(bytes);
  } catch (e) {
    print('Initial decode failed, patching numFmtId...');
    final patchedBytes = await _patchNumFmtId(bytes);
    excel = Excel.decodeBytes(patchedBytes);
  }

  final sheet = excel.tables.values.first;

  print('=== EXCEL FILE STRUCTURE ===');
  print('Total Sheets: ${excel.tables.length}');
  print('Sheet Names:');
  for (var sheetName in excel.tables.keys) {
    final s = excel.tables[sheetName]!;
    print('  - $sheetName (${s.maxColumns} cols x ${s.maxRows} rows)');
  }

  print('\n=== ANALYZING FIRST SHEET: ${excel.tables.keys.first} ===');
  print('Max Columns: ${sheet.maxColumns}');
  print('Max Rows: ${sheet.maxRows}');

  // Print first 15 rows to see metadata and headers
  print('--- METADATA AND HEADERS (Rows 1-15) ---');
  for (int row = 0; row < 15 && row < sheet.maxRows; row++) {
    print('\nRow ${row + 1}:');
    for (int col = 0; col < sheet.maxColumns; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
        final colLetter = _getColumnLetter(col);
        print('  $colLetter${row + 1} (col:$col): ${cell.value}');
      }
    }
  }

  // Check for week headers and structure
  print('\n--- CHECKING FOR WEEK PATTERNS ---');
  for (int row = 0; row < 15; row++) {
    for (int col = 0; col < sheet.maxColumns; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      final value = cell.value?.toString() ?? '';
      if (value.contains('الأسبوع') || value.contains('اسبوع')) {
        print(
          'Week header found at Row ${row + 1}, Col ${_getColumnLetter(col)} (col:$col): $value',
        );
      }
      if (value.contains('واجب') ||
          value.contains('نشاط') ||
          value.contains('شفوي')) {
        print(
          'Evaluation type at Row ${row + 1}, Col ${_getColumnLetter(col)} (col:$col): $value',
        );
      }
    }
  }

  // Sample a student row to see structure
  print('\n--- SAMPLE STUDENT ROW (Row 10) ---');
  final studentRow = 9; // Row 10
  for (int col = 0; col < sheet.maxColumns; col++) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: studentRow),
    );
    if (cell.value != null) {
      print(
        '  ${_getColumnLetter(col)}${studentRow + 1} (col:$col): ${cell.value}',
      );
    }
  }

  // Check for semester average column
  print('\n--- CHECKING FOR SEMESTER AVERAGE ---');
  for (int row = 0; row < 15; row++) {
    for (int col = 0; col < sheet.maxColumns; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      final value = cell.value?.toString() ?? '';
      if (value.contains('متوسط') ||
          value.contains('الفصل') ||
          value.contains('الدراسي')) {
        print(
          'Semester text at Row ${row + 1}, Col ${_getColumnLetter(col)} (col:$col): $value',
        );
      }
    }
  }

  // Check columns after week 5 to see if there are more weeks or semester average
  print('\n--- CHECKING COLUMNS AFTER WEEK 5 (cols 43+) ---');
  for (int col = 43; col < sheet.maxColumns && col < 150; col++) {
    bool hasContent = false;
    for (int row = 0; row < 15; row++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
        hasContent = true;
        print(
          'Col ${_getColumnLetter(col)} (col:$col), Row ${row + 1}: ${cell.value}',
        );
      }
    }
    if (!hasContent && col > 50) break; // Stop if we hit empty columns
  }

  // Print column headers (likely row 7 or 8)
  print('\n--- ROW 7 (Headers?) ---');
  final headerRow = 6; // Row 7
  for (int col = 0; col < sheet.maxColumns; col++) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow),
    );
    if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
      print('  ${_getColumnLetter(col)}7 (col:$col): ${cell.value}');
    }
  }

  print('\n--- ROW 8 (Sub-headers?) ---');
  final subHeaderRow = 7; // Row 8
  for (int col = 0; col < sheet.maxColumns; col++) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: subHeaderRow),
    );
    if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
      print('  ${_getColumnLetter(col)}8 (col:$col): ${cell.value}');
    }
  }

  print('\n--- ROW 9 (More headers?) ---');
  final row9 = 8; // Row 9
  for (int col = 0; col < sheet.maxColumns; col++) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row9),
    );
    if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
      print('  ${_getColumnLetter(col)}9 (col:$col): ${cell.value}');
    }
  }
}

String _getColumnLetter(int col) {
  String result = '';
  int num = col;
  while (num >= 0) {
    result = String.fromCharCode(65 + (num % 26)) + result;
    num = (num ~/ 26) - 1;
  }
  return result;
}

Future<Uint8List> _patchNumFmtId(Uint8List bytes) async {
  final archive = ZipDecoder().decodeBytes(bytes);
  final newArchive = Archive();
  for (final file in archive.files) {
    if (file.name == 'xl/styles.xml') {
      String content = String.fromCharCodes(file.content as List<int>);
      content = content.replaceAllMapped(
        RegExp(r'<numFmt\s+numFmtId="(\d+)"[^>]*/?>'),
        (m) {
          final id = int.parse(m.group(1)!);
          return id < 164 ? '' : m.group(0)!;
        },
      );
      newArchive.addFile(
        ArchiveFile(file.name, content.length, content.codeUnits),
      );
    } else {
      newArchive.addFile(file);
    }
  }
  return Uint8List.fromList(ZipEncoder().encode(newArchive)!);
}
