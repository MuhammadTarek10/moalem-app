import 'package:injectable/injectable.dart';
import 'package:moalem/features/reports/data/strategies/export_strategies.dart';
import 'package:moalem/features/reports/domain/entities/excel_export_entity.dart';
import 'package:moalem/features/reports/domain/repositories/excel_export_repository.dart';

@injectable
class TemplateStrategyManager {
  // We can let DI inject them or just instantiate them here since they are stateless
  // But DI is better. For now let's just use a list.
  final List<TemplateStrategy> strategies = [
    PrePrimaryExportStrategy(),
    PrimaryExportStrategy(),
    PreparatoryExportStrategy(),
    SecondaryExportStrategy(),
    AttendanceExportStrategy(),
  ];

  TemplateStrategyManager();

  List<TemplateInfo> getTemplatesForStage(EducationalStage stage) {
    return strategies
        .where((s) => s.stage == stage)
        .map(
          (s) => TemplateInfo(
            name: s.templateName, // Changed from name to templateName
            assetPath: '',
            stage: s.stage,
            type: s.exportType,
          ),
        )
        .toList();
  }

  TemplateStrategy getStrategy({
    required EducationalStage stage,
    required ExportType exportType,
  }) {
    return strategies.firstWhere(
      (s) => s.stage == stage && s.exportType == exportType,
      orElse: () => throw Exception(
        'No template strategy found for stage $stage and type $exportType',
      ),
    );
  }

  Future<List<int>> exportExcel(ExcelExportEntity entity) async {
    final strategy = getStrategy(
      stage: entity.stage,
      exportType: entity.exportType,
    );

    final workbook = await strategy.prepareWorkbook();

    // Set RTL
    if (workbook.worksheets.count > 0) {
      workbook.worksheets[0].isRightToLeft = true;
    }

    await strategy.execute(workbook, entity);

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    return bytes;
  }
}
