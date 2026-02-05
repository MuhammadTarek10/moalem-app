import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';

part 'qr_print_state.freezed.dart';

@freezed
abstract class QrPrintState with _$QrPrintState {
  const factory QrPrintState({
    @Default(AsyncLoading()) AsyncValue<List<ClassEntity>> classes,
    String? selectedClassId,
    @Default(AsyncData([])) AsyncValue<List<StudentEntity>> students,
    @Default(<String>{}) Set<String> selectedStudentIds,
    @Default(false) bool isExportingPdf,
    String? exportMessage,
  }) = _QrPrintState;
}
