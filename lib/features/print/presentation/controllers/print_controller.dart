import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_classes_usecase.dart';
import 'package:moalem/features/print/data/services/excel_export_service.dart';
import 'package:moalem/features/print/data/services/pdf_export_service.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/print/domain/usecases/generate_attendance_report_usecase.dart';
import 'package:moalem/features/print/domain/usecases/generate_scores_report_usecase.dart';

/// State for the print screen
class PrintState {
  final AsyncValue<List<ClassEntity>> classes;
  final String? selectedClassId;
  final PrintType printType;
  final AsyncValue<PrintDataEntity?> printData;
  final PeriodType periodType;
  final int periodNumber;
  final bool isExporting;
  final String? exportMessage;

  const PrintState({
    this.classes = const AsyncValue.loading(),
    this.selectedClassId,
    this.printType = PrintType.scores,
    this.printData = const AsyncValue.loading(),
    this.periodType = PeriodType.weekly,
    this.periodNumber = 1,
    this.isExporting = false,
    this.exportMessage,
  });

  PrintState copyWith({
    AsyncValue<List<ClassEntity>>? classes,
    String? selectedClassId,
    PrintType? printType,
    AsyncValue<PrintDataEntity?>? printData,
    PeriodType? periodType,
    int? periodNumber,
    bool? isExporting,
    String? exportMessage,
  }) {
    return PrintState(
      classes: classes ?? this.classes,
      selectedClassId: selectedClassId ?? this.selectedClassId,
      printType: printType ?? this.printType,
      printData: printData ?? this.printData,
      periodType: periodType ?? this.periodType,
      periodNumber: periodNumber ?? this.periodNumber,
      isExporting: isExporting ?? this.isExporting,
      exportMessage: exportMessage ?? this.exportMessage,
    );
  }
}

final printControllerProvider =
    StateNotifierProvider.family<PrintController, PrintState, String>((
      ref,
      printType,
    ) {
      return PrintController(
        printType,
        getIt<GetClassesUseCase>(),
        getIt<GenerateScoresReportUseCase>(),
        getIt<GenerateAttendanceReportUseCase>(),
        getIt<ExcelExportService>(),
        getIt<PdfExportService>(),
      );
    });

class PrintController extends StateNotifier<PrintState> {
  final GetClassesUseCase _getClassesUseCase;
  final GenerateScoresReportUseCase _generateScoresReportUseCase;
  final GenerateAttendanceReportUseCase _generateAttendanceReportUseCase;
  final ExcelExportService _excelExportService;
  final PdfExportService _pdfExportService;

  PrintController(
    String printTypeString,
    this._getClassesUseCase,
    this._generateScoresReportUseCase,
    this._generateAttendanceReportUseCase,
    this._excelExportService,
    this._pdfExportService,
  ) : super(
        PrintState(
          printType: printTypeString == 'attendance'
              ? PrintType.attendance
              : PrintType.scores,
        ),
      ) {
    loadClasses();
  }

  /// Load all classes
  Future<void> loadClasses() async {
    state = state.copyWith(classes: const AsyncValue.loading());
    try {
      final classes = await _getClassesUseCase();
      state = state.copyWith(
        classes: AsyncValue.data(classes),
        selectedClassId: classes.isNotEmpty ? classes.first.id : null,
      );

      // Auto-load print data for first class
      if (classes.isNotEmpty) {
        await loadPrintData();
      }
    } catch (e, stack) {
      state = state.copyWith(classes: AsyncValue.error(e, stack));
    }
  }

  /// Select a class
  Future<void> selectClass(String classId) async {
    if (state.selectedClassId == classId) return;
    state = state.copyWith(selectedClassId: classId);
    await loadPrintData();
  }

  /// Change period number
  Future<void> changePeriodNumber(int number) async {
    if (state.periodNumber == number) return;
    state = state.copyWith(periodNumber: number);
    await loadPrintData();
  }

  /// Load print data based on type
  Future<void> loadPrintData() async {
    final classId = state.selectedClassId;
    if (classId == null) return;

    state = state.copyWith(printData: const AsyncValue.loading());
    try {
      PrintDataEntity? printData;

      if (state.printType == PrintType.scores) {
        printData = await _generateScoresReportUseCase(
          classId,
          state.periodType,
          state.periodNumber,
        );
      } else if (state.printType == PrintType.attendance) {
        printData = await _generateAttendanceReportUseCase(
          classId,
          state.periodType,
          state.periodNumber,
        );
      }

      state = state.copyWith(printData: AsyncValue.data(printData));
    } catch (e, stack) {
      state = state.copyWith(printData: AsyncValue.error(e, stack));
    }
  }

  /// Export to Excel (runs in background to prevent UI freeze)
  Future<void> exportToExcel() async {
    final printData = state.printData.value;
    if (printData == null) return;

    state = state.copyWith(isExporting: true, exportMessage: null);
    try {
      // Run export in background
      await _excelExportService.exportToExcel(printData);
      state = state.copyWith(
        isExporting: false,
        exportMessage: 'تم تصدير Excel بنجاح',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        exportMessage: 'فشل تصدير Excel: $e',
      );
    }
  }

  /// Export to PDF (runs in background to prevent UI freeze)
  Future<void> exportToPdf() async {
    final printData = state.printData.value;
    if (printData == null) return;

    state = state.copyWith(isExporting: true, exportMessage: null);
    try {
      // Run export in background
      await _pdfExportService.exportToPdf(printData);
      state = state.copyWith(
        isExporting: false,
        exportMessage: 'تم تصدير PDF بنجاح',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        exportMessage: 'فشل تصدير PDF: $e',
      );
    }
  }

  /// Clear export message
  void clearExportMessage() {
    state = state.copyWith(exportMessage: null);
  }
}
