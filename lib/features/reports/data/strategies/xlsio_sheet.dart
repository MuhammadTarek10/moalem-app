// import 'package:excel/excel.dart';

// /// Wrapper around excel package's Sheet to provide a consistent API
// /// Used by template strategies.
// class XlsioSheet {
//   final Sheet _sheet;

//   XlsioSheet(this._sheet);

//   /// row and col are 1-indexed (to maintain compatibility with Syncfusion logic)
//   void text(int row, int col, String value, {CellStyle? style}) {
//     final cellIndex = CellIndex.indexByColumnRow(
//       columnIndex: col - 1,
//       rowIndex: row - 1,
//     );
//     _sheet.updateCell(cellIndex, TextCellValue(value));
//     final cellData = _sheet.cell(cellIndex);

//     if (style != null) {
//       cellData.cellStyle = style;
//     } else {
//       // Default style to ensure black text and no underline
//       cellData.cellStyle = CellStyle(
//         fontColorHex: ExcelColor.fromHexString('#000000'),
//         fontFamily: 'Noto Kufi Arabic',
//         underline: Underline.None,
//       );
//     }
//   }

//   /// row and col are 1-indexed
//   void number(int row, int col, num value, {CellStyle? style}) {
//     final cellIndex = CellIndex.indexByColumnRow(
//       columnIndex: col - 1,
//       rowIndex: row - 1,
//     );
//     _sheet.updateCell(cellIndex, DoubleCellValue(value.toDouble()));
//     final cellData = _sheet.cell(cellIndex);

//     if (style != null) {
//       cellData.cellStyle = style;
//     } else {
//       // Default style to ensure black text and no underline
//       cellData.cellStyle = CellStyle(
//         fontColorHex: ExcelColor.fromHexString('#000000'),
//         fontFamily: 'Noto Kufi Arabic',
//         underline: Underline.None,
//       );
//     }
//   }

//   /// Sets header style and borders for a cell (horizontal only)
//   void setHeaderStyle(int row, int col) {
//     final cellIndex = CellIndex.indexByColumnRow(
//       columnIndex: col - 1,
//       rowIndex: row - 1,
//     );
//     final cellData = _sheet.cell(cellIndex);

//     cellData.cellStyle = (cellData.cellStyle ?? CellStyle()).copyWith(
//       rotationVal: 0,
//       fontColorHexVal: ExcelColor.fromHexString('#000000'),
//       fontFamilyVal: 'Noto Kufi Arabic',
//       underlineVal: Underline.None,
//       horizontalAlignVal: HorizontalAlign.Center,
//       verticalAlignVal: VerticalAlign.Center,
//       boldVal: true,
//     );
//   }

//   /// Sets borders for a cell
//   void setBorder(int row, int col, {bool thick = false}) {
//     final cellIndex = CellIndex.indexByColumnRow(
//       columnIndex: col - 1,
//       rowIndex: row - 1,
//     );
//     final cellData = _sheet.cell(cellIndex);

//     final borderStyle = thick ? BorderStyle.Medium : BorderStyle.Thin;
//     cellData.cellStyle = (cellData.cellStyle ?? CellStyle()).copyWith(
//       topBorderVal: Border(borderStyle: borderStyle),
//       bottomBorderVal: Border(borderStyle: borderStyle),
//       leftBorderVal: Border(borderStyle: borderStyle),
//       rightBorderVal: Border(borderStyle: borderStyle),
//     );
//   }

//   /// Sets consistent font and alignment for data cells
//   void setDataStyle(int row, int col, {bool bold = false}) {
//     final cellIndex = CellIndex.indexByColumnRow(
//       columnIndex: col - 1,
//       rowIndex: row - 1,
//     );
//     final cellData = _sheet.cell(cellIndex);

//     cellData.cellStyle = (cellData.cellStyle ?? CellStyle()).copyWith(
//       fontFamilyVal: 'Noto Kufi Arabic',
//       horizontalAlignVal: HorizontalAlign.Center,
//       verticalAlignVal: VerticalAlign.Center,
//       boldVal: bold,
//     );
//   }

//   /// row and col are 1-indexed
//   String? getText(int row, int col) {
//     final cellData = _sheet.cell(
//       CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1),
//     );
//     return cellData.value?.toString();
//   }
// }
