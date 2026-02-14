import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:moalem/features/reports/domain/usecases/export_yearly_work_usecase.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

/// Service for Excel operations using syncfusion_flutter_xlsio
@injectable
class SyncfusionExcelService {
  /// Create new workbook (for fallback)
  Workbook createWorkbook() {
    return Workbook();
  }

  /// Apply cell style while preserving existing formatting
  void applyCellStyle({
    required Worksheet sheet,
    required int row,
    required int column,
    required SyncfusionCellStyle style,
  }) {
    final range = sheet.getRangeByIndex(row + 1, column + 1);

    // Apply style properties
    if (style.bold != null) {
      range.cellStyle.bold = style.bold!;
    }
    if (style.fontSize != null) {
      range.cellStyle.fontSize = style.fontSize!;
    }
    if (style.horizontalAlign != null) {
      range.cellStyle.hAlign = _mapHAlign(style.horizontalAlign!);
    }
    if (style.verticalAlign != null) {
      range.cellStyle.vAlign = _mapVAlign(style.verticalAlign!);
    }
    if (style.rotation != null) {
      range.cellStyle.rotation = style.rotation!;
    }
    if (style.fontName != null) {
      range.cellStyle.fontName = style.fontName!;
    }
    if (style.fontColor != null) {
      // Set font color directly as hex string
      range.cellStyle.fontColor = style.fontColor!;
    }
    if (style.backgroundColor != null) {
      range.cellStyle.backColor = style.backgroundColor!;
    }
  }

  /// Set cell value with proper type handling
  void setCellValue({
    required Worksheet sheet,
    required int row,
    required int column,
    required dynamic value,
  }) {
    final range = sheet.getRangeByIndex(row + 1, column + 1);

    if (value is String) {
      range.setText(value);
    } else if (value is int) {
      range.setNumber(value.toDouble());
    } else if (value is double) {
      range.setNumber(value);
    } else if (value is DateTime) {
      range.setDateTime(value);
    } else if (value == null) {
      range.setText('');
    } else {
      range.setText(value.toString());
    }
  }

  /// Merge cells
  void mergeCells({
    required Worksheet sheet,
    required int startRow,
    required int startColumn,
    required int endRow,
    required int endColumn,
  }) {
    final range = sheet.getRangeByIndex(
      startRow + 1,
      startColumn + 1,
      endRow + 1,
      endColumn + 1,
    );
    range.merge();
  }

  /// Set column width
  void setColumnWidth({
    required Worksheet sheet,
    required int column,
    required double width,
  }) {
    sheet.getRangeByIndex(1, column + 1).columnWidth = width;
  }

  /// Set row height
  void setRowHeight({
    required Worksheet sheet,
    required int row,
    required double height,
  }) {
    sheet.getRangeByIndex(row + 1, 1).rowHeight = height;
  }

  /// Copy sheet - simplified version
  void copySheet({
    required Workbook workbook,
    required String sourceName,
    required String newName,
  }) {
    // Find source sheet by iterating
    Worksheet? sourceSheet;
    for (int i = 0; i < workbook.worksheets.count; i++) {
      if (workbook.worksheets[i].name == sourceName) {
        sourceSheet = workbook.worksheets[i];
        break;
      }
    }

    if (sourceSheet == null) {
      throw ExcelExportException('Source sheet not found: $sourceName');
    }

    final newSheet = workbook.worksheets.addWithName(newName);

    // Copy worksheet settings
    newSheet.isRightToLeft = sourceSheet.isRightToLeft;

    // Copy cells - iterate through a reasonable range
    // Note: syncfusion_flutter_xlsio doesn't have getUsedRange
    // We'll copy a fixed range based on template expectations
    const maxRows = 250;
    const maxCols = 50;

    for (int row = 1; row <= maxRows; row++) {
      for (int col = 1; col <= maxCols; col++) {
        final sourceCell = sourceSheet.getRangeByIndex(row, col);
        final targetCell = newSheet.getRangeByIndex(row, col);

        // Copy value if cell has content
        final text = sourceCell.displayText;
        if (text.isNotEmpty) {
          targetCell.setText(text);
        }

        // Copy number if present
        try {
          final number = sourceCell.number;
          if (number != null && number != 0) {
            targetCell.setNumber(number);
          }
        } catch (_) {
          // Not a number cell
        }

        // Copy basic styles
        targetCell.cellStyle.bold = sourceCell.cellStyle.bold;
        targetCell.cellStyle.fontSize = sourceCell.cellStyle.fontSize;
        targetCell.cellStyle.hAlign = sourceCell.cellStyle.hAlign;
        targetCell.cellStyle.vAlign = sourceCell.cellStyle.vAlign;
        targetCell.cellStyle.fontName = sourceCell.cellStyle.fontName;
      }
    }

    // Copy column widths
    for (int col = 1; col <= maxCols; col++) {
      newSheet.getRangeByIndex(1, col).columnWidth = sourceSheet
          .getRangeByIndex(1, col)
          .columnWidth;
    }
  }

  /// Save workbook to bytes
  Uint8List saveWorkbook(Workbook workbook) {
    try {
      final bytes = workbook.saveAsStream();
      return Uint8List.fromList(bytes);
    } catch (e) {
      throw ExcelExportException('Failed to save workbook: $e');
    }
  }

  /// Dispose workbook to free memory
  void disposeWorkbook(Workbook workbook) {
    workbook.dispose();
  }

  // Private helper methods
  HAlignType _mapHAlign(HorizontalAlign align) {
    switch (align) {
      case HorizontalAlign.left:
        return HAlignType.left;
      case HorizontalAlign.center:
        return HAlignType.center;
      case HorizontalAlign.right:
        return HAlignType.right;
    }
  }

  VAlignType _mapVAlign(VerticalAlign align) {
    switch (align) {
      case VerticalAlign.top:
        return VAlignType.top;
      case VerticalAlign.center:
        return VAlignType.center;
      case VerticalAlign.bottom:
        return VAlignType.bottom;
    }
  }
}

/// Cell style for Syncfusion Excel
class SyncfusionCellStyle {
  final bool? bold;
  final double? fontSize;
  final HorizontalAlign? horizontalAlign;
  final VerticalAlign? verticalAlign;
  final int? rotation;
  final String? fontName;
  final String? fontColor;
  final String? backgroundColor;

  const SyncfusionCellStyle({
    this.bold,
    this.fontSize,
    this.horizontalAlign,
    this.verticalAlign,
    this.rotation,
    this.fontName,
    this.fontColor,
    this.backgroundColor,
  });
}

/// Horizontal alignment options
enum HorizontalAlign { left, center, right }

/// Vertical alignment options
enum VerticalAlign { top, center, bottom }
