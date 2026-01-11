import 'package:injectable/injectable.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// Service to create Excel workbooks for print export
/// Note: Syncfusion xlsio can only CREATE Excel files, not read them.
/// So we create the structure from scratch instead of loading templates.
@injectable
class TemplateLoaderService {
  /// Create a new workbook with the appropriate structure for the print data
  Future<xlsio.Workbook> loadTemplate(String templatePath) async {
    // Create a new workbook (Syncfusion xlsio can only create, not read)
    final workbook = xlsio.Workbook();
    return workbook;
  }

  /// Get the first sheet from a workbook
  xlsio.Worksheet? getFirstSheet(xlsio.Workbook workbook) {
    if (workbook.worksheets.count == 0) return null;
    return workbook.worksheets[0];
  }

  /// Find a cell by its value - returns null since we create from scratch
  ({int row, int column})? findCellByValue(
    xlsio.Worksheet sheet,
    String value,
  ) {
    // Since we create from scratch, we don't need to find cells
    return null;
  }

  /// Return the data start row (after header)
  int findDataStartRow(xlsio.Worksheet sheet) {
    // Data starts at row 10 (after metadata and headers)
    return 10;
  }
}
