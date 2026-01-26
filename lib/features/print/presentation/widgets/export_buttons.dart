import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';

class ExportButtons extends StatelessWidget {
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final VoidCallback? onExportEmptySheet;
  final bool isExcelLoading;
  final bool isPdfLoading;
  final bool isEmptySheetLoading;
  final bool showEmptySheetButton;

  const ExportButtons({
    super.key,
    required this.onExportExcel,
    required this.onExportPdf,
    this.onExportEmptySheet,
    this.isExcelLoading = false,
    this.isPdfLoading = false,
    this.isEmptySheetLoading = false,
    this.showEmptySheetButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = isExcelLoading || isPdfLoading || isEmptySheetLoading;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Excel button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onExportExcel,
                  icon: isExcelLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.table_chart, size: 20),
                  label: Text(AppStrings.exportExcel.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // PDF button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onExportPdf,
                  icon: isPdfLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, size: 20),
                  label: Text(AppStrings.exportPdf.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Empty sheet button (only for attendance)
          if (showEmptySheetButton && onExportEmptySheet != null) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onExportEmptySheet,
                icon: isEmptySheetLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download_outlined, size: 20),
                label: const Text('تصدير كشف فارغ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
