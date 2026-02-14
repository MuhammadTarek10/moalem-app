import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/classes/presentation/models/student_form_data.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/app_button.dart';
import 'package:moalem/shared/widgets/text_input.dart';

class AddOrEditStudentDialog extends StatefulWidget {
  final StudentFormData? initialData;
  final int studentsCount;

  const AddOrEditStudentDialog({
    super.key,
    this.initialData,
    this.studentsCount = 0,
  });

  /// Shows the dialog and returns the form data if submitted, null if cancelled
  static Future<StudentFormData?> show(
    BuildContext context, {
    StudentFormData? initialData,
    int studentsCount = 0,
  }) {
    return showModalBottomSheet<StudentFormData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddOrEditStudentDialog(
        initialData: initialData,
        studentsCount: studentsCount,
      ),
    );
  }

  @override
  State<AddOrEditStudentDialog> createState() => _AddOrEditStudentDialogState();
}

class _AddOrEditStudentDialogState extends State<AddOrEditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late StudentFormData _formData;

  bool get _isEditing => widget.initialData?.isEditing ?? false;

  @override
  void initState() {
    super.initState();
    _formData =
        widget.initialData ?? StudentFormData(number: widget.studentsCount + 1);
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_formData);
    }
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // bottom: true,
      // maintainBottomViewPadding: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 270.h,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.r),
              bottom: Radius.circular(20.r),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEditing
                                ? AppStrings.editStudentTitle.tr()
                                : AppStrings.addStudentTitle.tr(),
                            style: context.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _onCancel,
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Form fields - Student Name field
                      AppTextFormField(
                        initialValue: _formData.name,
                        hint: AppStrings.studentNameLabel.tr(),
                        onChanged: (value) =>
                            _formData = _formData.copyWith(name: value),
                        validator: requiredValidator,
                      ),
                      SizedBox(height: 24.h),

                      // Action Buttons - side by side
                      Row(
                        children: [
                          // Add/Save Button
                          Expanded(
                            child: AppButton(
                              onPressed: _onSubmit,
                              text: _isEditing
                                  ? AppStrings.saveButton.tr()
                                  : AppStrings.addButton.tr(),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          // Cancel Button
                          Expanded(
                            child: AppButton(
                              onPressed: _onCancel,
                              text: AppStrings.cancelButton.tr(),
                              outlined: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
