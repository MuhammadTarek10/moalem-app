import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/classes/presentation/models/add_class_form_data.dart';
import 'package:moalem/features/profile/presentation/controllers/profile_controller.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/utils/validators.dart';
import 'package:moalem/shared/widgets/app_button.dart';
import 'package:moalem/shared/widgets/dropdown_field.dart';
import 'package:moalem/shared/widgets/text_input.dart';

class AddOrEditClassDialog extends ConsumerStatefulWidget {
  final ClassFormData? initialData;

  const AddOrEditClassDialog({super.key, this.initialData});

  /// Shows the dialog and returns the form data if submitted, null if cancelled
  static Future<ClassFormData?> show(
    BuildContext context, {
    ClassFormData? initialData,
  }) {
    return showModalBottomSheet<ClassFormData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddOrEditClassDialog(initialData: initialData),
    );
  }

  @override
  ConsumerState<AddOrEditClassDialog> createState() =>
      _AddOrEditClassDialogState();
}

class _AddOrEditClassDialogState extends ConsumerState<AddOrEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late ClassFormData _formData;

  bool get _isEditing => widget.initialData?.isEditing ?? false;

  // Semesters are static as they're not user-specific
  final List<String> _semesters = [
    'الفصل الدراسى الأول',
    'الفصل الدراسى الثانى',
  ];

  @override
  void initState() {
    super.initState();
    _formData = widget.initialData ?? const ClassFormData();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_formData);
    }
  }

  void _onClose() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(profileControllerProvider);

    return Container(
      height: context.screenHeight * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing
                      ? AppStrings.editClassTitle.tr()
                      : AppStrings.addClassTitle.tr(),
                  style: context.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  onPressed: _onClose,
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: userState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (user) => Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      SizedBox(height: 8.h),

                      // Educational Stage (grades from user)
                      DropdownField(
                        value: _formData.educationalStage,
                        items: user.grades,
                        hint: AppStrings.educationalStageHint.tr(),
                        onChanged: (value) => _formData = _formData.copyWith(
                          educationalStage: value,
                        ),
                        validator: requiredValidator,
                      ),
                      SizedBox(height: 20.h),

                      // Class Name
                      AppTextFormField(
                        initialValue: _formData.className,
                        hint: AppStrings.classNameLabel.tr(),
                        onChanged: (value) =>
                            _formData = _formData.copyWith(className: value),
                        validator: requiredValidator,
                      ),
                      SizedBox(height: 20.h),

                      // Subject (from user)
                      DropdownField(
                        value: _formData.subject,
                        items: user.subjects,
                        hint: AppStrings.subjectFieldHint.tr(),
                        onChanged: (value) =>
                            _formData = _formData.copyWith(subject: value),
                        validator: requiredValidator,
                      ),
                      SizedBox(height: 20.h),

                      // Semester (static)
                      DropdownField(
                        value: _formData.semester,
                        items: _semesters,
                        hint: AppStrings.semesterHint.tr(),
                        onChanged: (value) =>
                            _formData = _formData.copyWith(semester: value),
                        validator: requiredValidator,
                      ),
                      SizedBox(height: 20.h),

                      // School (from user)
                      DropdownField(
                        value: _formData.school,
                        items: user.schools,
                        hint: AppStrings.schoolFieldHint.tr(),
                        onChanged: (value) =>
                            _formData = _formData.copyWith(school: value),
                        validator: requiredValidator,
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
            child: SafeArea(
              child: AppButton(
                onPressed: _onSubmit,
                text: AppStrings.saveButton.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
