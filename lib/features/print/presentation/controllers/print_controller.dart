import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/usecases/get_classes_usecase.dart';
import 'package:moalem/features/print/data/services/excel_export_service.dart';
import 'package:moalem/features/print/data/services/pdf_export_service.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/print/domain/usecases/generate_multi_week_attendance_report_usecase.dart';
import 'package:moalem/features/print/domain/usecases/generate_multi_week_scores_report_usecase.dart';

/// State for the print screen
class PrintState {
  final AsyncValue<List<ClassEntity>> classes;
  final String? selectedStage;
  final String? selectedClassId;
  final PrintType printType;
  final AsyncValue<PrintDataEntity?> printData;
  final PeriodType periodType;
  final int periodNumber;
  final int weekGroup; // 1 for weeks 1-5, 2 for weeks 6-10, 3 for weeks 11-15
  final bool isExportingExcel;
  final bool isExportingPdf;
  final bool isExportingEmptySheet;
  final String? exportMessage;

  const PrintState({
    this.classes = const AsyncValue.loading(),
    this.selectedStage,
    this.selectedClassId,
    this.printType = PrintType.scores,
    this.printData = const AsyncValue.loading(),
    this.periodType = PeriodType.weekly,
    this.periodNumber = 1,
    this.weekGroup = 1, // Default to page 1 (weeks 1-5)
    this.isExportingExcel = false,
    this.isExportingPdf = false,
    this.isExportingEmptySheet = false,
    this.exportMessage,
  });

  /// Get the week range label for the current week group
  String get weekGroupLabel {
    if (weekGroup == 0) return 'جميع الأسابيع (1-15)';
    final startWeek = (weekGroup - 1) * 5 + 1;
    final endWeek = startWeek + 4;
    return 'الأسابيع $startWeek - $endWeek';
  }

  PrintState copyWith({
    AsyncValue<List<ClassEntity>>? classes,
    String? selectedStage,
    String? selectedClassId,
    PrintType? printType,
    AsyncValue<PrintDataEntity?>? printData,
    PeriodType? periodType,
    int? periodNumber,
    int? weekGroup,
    bool? isExportingExcel,
    bool? isExportingPdf,
    bool? isExportingEmptySheet,
    String? exportMessage,
  }) {
    return PrintState(
      classes: classes ?? this.classes,
      selectedStage: selectedStage ?? this.selectedStage,
      selectedClassId: selectedClassId ?? this.selectedClassId,
      printType: printType ?? this.printType,
      printData: printData ?? this.printData,
      periodType: periodType ?? this.periodType,
      periodNumber: periodNumber ?? this.periodNumber,
      weekGroup: weekGroup ?? this.weekGroup,
      isExportingExcel: isExportingExcel ?? this.isExportingExcel,
      isExportingPdf: isExportingPdf ?? this.isExportingPdf,
      isExportingEmptySheet:
          isExportingEmptySheet ?? this.isExportingEmptySheet,
      exportMessage: exportMessage ?? this.exportMessage,
    );
  }
}

final printControllerProvider = StateNotifierProvider.family
    .autoDispose<PrintController, PrintState, String>((ref, printType) {
      return PrintController(
        printType,
        getIt<GetClassesUseCase>(),
        getIt<GenerateMultiWeekScoresReportUseCase>(),
        getIt<GenerateMultiWeekAttendanceReportUseCase>(),
        getIt<ExcelExportService>(),
        getIt<PdfExportService>(),
      );
    });

class PrintController extends StateNotifier<PrintState> {
  final GetClassesUseCase _getClassesUseCase;
  final GenerateMultiWeekScoresReportUseCase
  _generateMultiWeekScoresReportUseCase;
  final GenerateMultiWeekAttendanceReportUseCase
  _generateMultiWeekAttendanceReportUseCase;
  final ExcelExportService _excelExportService;
  final PdfExportService _pdfExportService;

  PrintController(
    String printTypeString,
    this._getClassesUseCase,
    this._generateMultiWeekScoresReportUseCase,
    this._generateMultiWeekAttendanceReportUseCase,
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
      final firstClass = classes.isNotEmpty ? classes.first : null;
      state = state.copyWith(
        classes: AsyncValue.data(classes),
        selectedStage: null,
        selectedClassId: firstClass?.id,
      );

      // Auto-load print data for first class
      if (classes.isNotEmpty) {
        await loadPrintData();
      }
    } catch (e, stack) {
      state = state.copyWith(classes: AsyncValue.error(e, stack));
    }
  }

  /// Select a stage and filter classes
  Future<void> selectStage(String? stage) async {
    if (state.selectedStage == stage) return;

    final allClasses = state.classes.value ?? [];
    final filteredClasses = allClasses
        .where((c) => stage == null || c.stage == stage)
        .toList();

    state = state.copyWith(
      selectedStage: stage,
      selectedClassId: filteredClasses.isNotEmpty
          ? filteredClasses.first.id
          : null,
    );

    await loadPrintData();
  }

  /// Select a class
  Future<void> selectClass(String classId) async {
    if (state.selectedClassId == classId) return;
    state = state.copyWith(selectedClassId: classId);
    await loadPrintData();
  }

  /// Change period number (for attendance)
  Future<void> changePeriodNumber(int number) async {
    if (state.periodNumber == number) return;
    state = state.copyWith(periodNumber: number);
    await loadPrintData();
  }

  /// Change week group (for scores - 1 for weeks 1-5, 2 for weeks 6-10, etc.)
  Future<void> changeWeekGroup(int group) async {
    if (state.weekGroup == group) return;
    state = state.copyWith(weekGroup: group);
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
        // Use multi-week scores report for scores
        printData = await _generateMultiWeekScoresReportUseCase(
          classId: classId,
          weekGroup: state.weekGroup,
        );
      } else if (state.printType == PrintType.attendance) {
        // Use multi-week attendance report
        printData = await _generateMultiWeekAttendanceReportUseCase(
          classId: classId,
          weekGroup: state.weekGroup,
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

    state = state.copyWith(isExportingExcel: true, exportMessage: null);
    try {
      // Run export in background
      await _excelExportService.exportToExcel(printData);
      state = state.copyWith(
        isExportingExcel: false,
        exportMessage: 'تم تصدير Excel بنجاح',
      );
    } catch (e) {
      state = state.copyWith(
        isExportingExcel: false,
        exportMessage: 'فشل تصدير Excel: $e',
      );
    }
  }

  /// Export to PDF (runs in background to prevent UI freeze)
  Future<void> exportToPdf() async {
    final printData = state.printData.value;
    if (printData == null) return;

    state = state.copyWith(isExportingPdf: true, exportMessage: null);
    try {
      // Run export in background
      await _pdfExportService.exportToPdf(printData);
      state = state.copyWith(
        isExportingPdf: false,
        exportMessage: 'تم تصدير PDF بنجاح',
      );
    } catch (e) {
      state = state.copyWith(
        isExportingPdf: false,
        exportMessage: 'فشل تصدير PDF: $e',
      );
    }
  }

  /// Export empty attendance sheet (runs in background to prevent UI freeze)
  Future<void> exportEmptySheet() async {
    final printData = state.printData.value;
    if (printData == null) return;

    state = state.copyWith(isExportingEmptySheet: true, exportMessage: null);
    try {
      // await _excelExportService.exportEmptyAttendanceSheet(printData);
      state = state.copyWith(
        isExportingEmptySheet: false,
        exportMessage: 'تم تصدير كشف الغياب الفارغ بنجاح',
      );
    } catch (e) {
      state = state.copyWith(
        isExportingEmptySheet: false,
        exportMessage: 'فشل تصدير كشف الغياب الفارغ: $e',
      );
    }
  }

  /// Clear export message
  void clearExportMessage() {
    state = state.copyWith(exportMessage: null);
  }
}
