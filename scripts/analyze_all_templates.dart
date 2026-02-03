// ignore_for_file: avoid_print
import 'dart:io';

import 'package:excel/excel.dart';

void main() async {
  final templates = {
    'PrePrimary': 'assets/files/كشف فارغ اعمال السنة اولى وتانية ابتدائى.xlsx',
    'Primary': 'assets/files/كشف فارغ اعمال السنة من 3ل6 ابتدائى.xlsx',
    'Secondary': 'assets/files/كشف فارغ اعمال السنة اعدادى.xlsx',
    'High': 'assets/files/كشف فارغ اعمال السنة ثانوى نظام شهور.xlsx',
  };

  final results = <String, Map<String, dynamic>>{};

  for (final entry in templates.entries) {
    print('\n${"=" * 60}');
    print('Analyzing: ${entry.key}');
    print('=' * 60);

    results[entry.key] = await _analyze(entry.value);
  }

  // Print summary
  print('\n\n${"#" * 60}');
  print('SUMMARY');
  print('#' * 60);

  for (final entry in results.entries) {
    print('\n${entry.key}:');
    entry.value.forEach((key, value) {
      print('  $key: $value');
    });
  }
}

Future<Map<String, dynamic>> _analyze(String path) async {
  final result = <String, dynamic>{};

  try {
    final file = File(path);
    if (!file.existsSync()) {
      print('  ERROR: File not found');
      return {'error': 'File not found'};
    }

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    result['sheetName'] = excel.tables.keys.first;
    result['maxRows'] = sheet.maxRows;
    result['maxCols'] = sheet.maxColumns;

    // Find metadata
    result['metaGovernorate'] = _findCell(sheet, 'مديرية');
    result['metaAdmin'] = _findCell(sheet, 'ادارة');
    result['metaSchool'] = _findCell(sheet, 'مدرسة');
    result['metaSubject'] = _findCell(sheet, 'مادة');
    result['metaTitle'] = _findCell(sheet, 'سجل');

    // Find student start row (look for serial number 1)
    result['studentStartRow'] = _findStudentRow(sheet);
    result['nameColumn'] = _findNameColumn(sheet);

    // Find week/month structure
    final weekInfo = _findWeekStructure(sheet);
    result['weekCount'] = weekInfo['count'];
    result['firstWeekCol'] = weekInfo['firstCol'];
    result['colsPerWeek'] = weekInfo['colsPerWeek'];

    // Print details
    print('  Sheet: ${result['sheetName']}');
    print(
      '  Dimensions: ${result['maxRows']} rows x ${result['maxCols']} cols',
    );
    print('  Metadata:');
    print('    Governorate: ${result['metaGovernorate']}');
    print('    Admin: ${result['metaAdmin']}');
    print('    School: ${result['metaSchool']}');
    print('    Subject: ${result['metaSubject']}');
    print('    Title: ${result['metaTitle']}');
    print('  Students:');
    print('    Start Row: ${result['studentStartRow']}');
    print('    Name Column: ${result['nameColumn']}');
    print('  Week Structure:');
    print('    Count: ${result['weekCount']}');
    print('    First Week Col: ${result['firstWeekCol']}');
    print('    Cols Per Week: ${result['colsPerWeek']}');
  } catch (e) {
    print('  ERROR: $e');
    result['error'] = e.toString();
  }

  return result;
}

String? _findCell(Sheet sheet, String pattern) {
  for (int row = 0; row < 10; row++) {
    for (int col = 0; col < 50; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (cell.value != null && cell.value.toString().contains(pattern)) {
        return '${_col(col)}${row + 1} (col=$col, row=$row)';
      }
    }
  }
  return null;
}

int? _findStudentRow(Sheet sheet) {
  for (int row = 0; row < 20; row++) {
    for (int col = 0; col < 5; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (cell.value != null) {
        final val = cell.value.toString();
        if (val == '1' || val == '1.0') {
          print('  Found serial 1 at ${_col(col)}${row + 1}');
          return row;
        }
      }
    }
  }
  return null;
}

int? _findNameColumn(Sheet sheet) {
  // Look for "الاسم" in header rows
  for (int row = 0; row < 15; row++) {
    for (int col = 0; col < 10; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (cell.value != null && cell.value.toString().contains('الاس')) {
        print('  Found name header at ${_col(col)}${row + 1}');
        return col;
      }
    }
  }
  return null;
}

Map<String, dynamic> _findWeekStructure(Sheet sheet) {
  final weekCols = <int>[];

  for (int row = 0; row < 10; row++) {
    for (int col = 0; col < sheet.maxColumns; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (cell.value != null) {
        final val = cell.value.toString();
        if (val.contains('أسبوع') ||
            val.contains('الأسبوع') ||
            val.contains('اسبوع')) {
          weekCols.add(col);
          print('  Week at ${_col(col)}${row + 1}: $val');
        }
      }
    }
  }

  if (weekCols.length >= 2) {
    final colsPerWeek = weekCols[1] - weekCols[0];
    return {
      'count': weekCols.length,
      'firstCol': weekCols.first,
      'colsPerWeek': colsPerWeek,
    };
  }

  return {
    'count': weekCols.length,
    'firstCol': weekCols.isNotEmpty ? weekCols.first : null,
    'colsPerWeek': null,
  };
}

String _col(int c) {
  String r = '';
  while (c >= 0) {
    r = String.fromCharCode((c % 26) + 65) + r;
    c = (c ~/ 26) - 1;
  }
  return r;
}
