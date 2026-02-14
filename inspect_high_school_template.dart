// import 'dart:io';

// import 'package:excel/excel.dart';

// void main() async {
//   var file = 'assets/files/كشف فارغ اعمال السنة ثانوى نظام شهور.xlsx';
//   if (!File(file).existsSync()) {
//     print('File not found: $file');
//     return;
//   }

//   var bytes = File(file).readAsBytesSync();
//   var excel = Excel.decodeBytes(bytes);

//   for (var table in excel.tables.keys) {
//     print('Sheet: $table');
//     var sheet = excel.tables[table]!;
//     for (int r = 0; r < 10; r++) {
//       var row = sheet.rows.length > r ? sheet.rows[r] : [];
//       var values = [];
//       for (int c = 0; c < 35; c++) {
//         var cell = row.length > c ? row[c] : null;
//         var val = cell?.value?.toString().replaceAll('\n', ' ') ?? '';
//         values.add('$c:$val');
//       }
//       print('Row $r: ${values.join(' | ')}');
//     }
//   }
// }
