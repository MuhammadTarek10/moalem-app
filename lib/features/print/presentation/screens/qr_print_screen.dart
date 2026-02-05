import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/print/presentation/controllers/qr_print_controller.dart';
import 'package:moalem/features/print/presentation/controllers/qr_print_state.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/loading_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPrintScreen extends ConsumerWidget {
  const QrPrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrPrintControllerProvider);
    final controller = ref.read(qrPrintControllerProvider.notifier);

    ref.listen(qrPrintControllerProvider, (previous, next) {
      if (next.exportMessage != null &&
          next.exportMessage != previous?.exportMessage) {
        context.showSuccessSnackBar(next.exportMessage!);
        controller.clearExportMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.qrPrintTitle.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: state.isExportingPdf
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            onPressed: state.isExportingPdf
                ? null
                : () => controller.exportToPdf(),
          ),
        ],
      ),
      body: state.classes.when(
        loading: () => const LoadingScreen(),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (classes) {
          if (classes.isEmpty) {
            return Center(child: Text(AppStrings.noClassesTitle.tr()));
          }

          return Column(
            children: [
              _buildFilters(context, state, controller, classes),
              _buildSelectionHeader(context, state, controller),
              Expanded(
                child: state.students.when(
                  loading: () => const LoadingScreen(),
                  error: (err, _) => Center(child: Text(err.toString())),
                  data: (students) {
                    if (students.isEmpty) {
                      return Center(
                        child: Text(AppStrings.noStudentsTitle.tr()),
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.all(16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.w,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isSelected = state.selectedStudentIds.contains(
                          student.id,
                        );

                        return GestureDetector(
                          onTap: () =>
                              controller.toggleStudentSelection(student.id),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.inactiveBorder,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 4,
                                  right: 0,
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textLight,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18.w,
                                    vertical: 15.h,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      QrImageView(
                                        data: student.qrCode,
                                        version: QrVersions.auto,
                                        size: 100.w,
                                      ),
                                      Text(
                                        student.name,
                                        style: context.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${AppStrings.studentIdLabel.tr()}: ${index + 1}',
                                        style: context.bodySmall.copyWith(
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    QrPrintState state,
    QrPrintController controller,
    List classes,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.selectClass.tr(),
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryLightest,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.inactiveBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.selectedClassId,
                items: classes
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.selectClass(value);
                },
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textLight,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(
    BuildContext context,
    QrPrintState state,
    QrPrintController controller,
  ) {
    final studentsSnapshot = state.students.asData?.value ?? [];
    final allSelected =
        studentsSnapshot.isNotEmpty &&
        state.selectedStudentIds.length == studentsSnapshot.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${AppStrings.selectedCount.tr()}: ${state.selectedStudentIds.length}',
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () => controller.toggleSelectAll(),
            icon: Icon(
              allSelected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank_outlined,
            ),
            label: Text(AppStrings.selectAll.tr()),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
