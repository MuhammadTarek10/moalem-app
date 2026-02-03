// import 'dart:io';

// import 'package:excel/excel.dart';

// void main() async {
//   var file = 'assets/files/كشف فارغ اعمال السنة اعدادى.xlsx';
//   var bytes = File(file).readAsBytesSync();
//   var excel = Excel.decodeBytes(bytes);

//   for (var table in excel.tables.keys) {
//     print('Sheet: $table');
//     for (var row in excel.tables[table]!.rows.take(15)) {
//       // Clean up values for printing
//       print(
//         row.map((e) => e?.value?.toString().replaceAll('\n', ' ')).toList(),
//       );
//     }
//   }
// }
