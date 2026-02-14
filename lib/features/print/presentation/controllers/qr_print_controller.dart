import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/classes/domain/usecases/get_classes_usecase.dart';
import 'package:moalem/features/print/data/services/qr_pdf_service.dart';
import 'package:moalem/features/print/presentation/controllers/qr_print_state.dart';
import 'package:moalem/features/students/domain/usecases/get_students_by_class_id_usecase.dart';

final qrPrintControllerProvider =
    StateNotifierProvider.autoDispose<QrPrintController, QrPrintState>((ref) {
      return QrPrintController(
        getIt<GetClassesUseCase>(),
        getIt<GetStudentsByClassIdUseCase>(),
        getIt<QrPdfService>(),
      );
    });

class QrPrintController extends StateNotifier<QrPrintState> {
  final GetClassesUseCase _getClassesUseCase;
  final GetStudentsByClassIdUseCase _getStudentsByClassIdUseCase;
  final QrPdfService _qrPdfService;

  QrPrintController(
    this._getClassesUseCase,
    this._getStudentsByClassIdUseCase,
    this._qrPdfService,
  ) : super(const QrPrintState()) {
    loadClasses();
  }

  Future<void> loadClasses() async {
    state = state.copyWith(classes: const AsyncValue.loading());
    try {
      final classes = await _getClassesUseCase();
      state = state.copyWith(
        classes: AsyncValue.data(classes),
        selectedClassId: classes.isNotEmpty ? classes.first.id : null,
      );
      if (state.selectedClassId != null) {
        loadStudents(state.selectedClassId!);
      }
    } catch (e, stack) {
      state = state.copyWith(classes: AsyncValue.error(e, stack));
    }
  }

  Future<void> loadStudents(String classId) async {
    state = state.copyWith(
      students: const AsyncValue.loading(),
      selectedStudentIds: {},
    );
    try {
      final students = await _getStudentsByClassIdUseCase(classId);
      state = state.copyWith(
        students: AsyncValue.data(students),
        selectedStudentIds: students
            .map((s) => s.id)
            .toSet(), // Default Select All
      );
    } catch (e, stack) {
      state = state.copyWith(students: AsyncValue.error(e, stack));
    }
  }

  void selectClass(String classId) {
    if (state.selectedClassId == classId) return;
    state = state.copyWith(selectedClassId: classId);
    loadStudents(classId);
  }

  void toggleStudentSelection(String studentId) {
    final selectedIds = Set<String>.from(state.selectedStudentIds);
    if (selectedIds.contains(studentId)) {
      selectedIds.remove(studentId);
    } else {
      selectedIds.add(studentId);
    }
    state = state.copyWith(selectedStudentIds: selectedIds);
  }

  void toggleSelectAll() {
    state.students.whenData((students) {
      if (state.selectedStudentIds.length == students.length) {
        state = state.copyWith(selectedStudentIds: {});
      } else {
        state = state.copyWith(
          selectedStudentIds: students.map((s) => s.id).toSet(),
        );
      }
    });
  }

  Future<void> exportToPdf() async {
    if (state.selectedStudentIds.isEmpty) return;

    state = state.copyWith(isExportingPdf: true);
    try {
      final students = state.students.asData?.value ?? [];
      final selectedStudents =
          students
              .where((s) => state.selectedStudentIds.contains(s.id))
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number));

      if (selectedStudents.isEmpty) return;

      await _qrPdfService.generateAndPrintQrCodes(selectedStudents);
      state = state.copyWith(
        isExportingPdf: false,
        exportMessage: 'تم إنشاء ملف PDF بنجاح',
      );
    } catch (e) {
      state = state.copyWith(
        isExportingPdf: false,
        exportMessage: 'فشل إنشاء ملف PDF',
      );
    }
  }

  void clearExportMessage() {
    state = state.copyWith(exportMessage: null);
  }
}
