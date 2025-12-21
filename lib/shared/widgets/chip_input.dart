import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';

class ChipInputField extends StatefulWidget {
  const ChipInputField({
    super.key,
    required this.selectedItems,
    required this.onItemsChanged,
    required this.hint,
    this.validator,
  });

  final List<String> selectedItems;
  final ValueChanged<List<String>> onItemsChanged;
  final String hint;
  final FormFieldValidator<List<String>>? validator;

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final _textController = TextEditingController();

  void _addItem() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !widget.selectedItems.contains(text)) {
      final newList = [...widget.selectedItems, text];
      widget.onItemsChanged(newList);
      _textController.clear();
    }
  }

  void _removeItem(String item) {
    final newList = widget.selectedItems.where((e) => e != item).toList();
    widget.onItemsChanged(newList);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: widget.selectedItems,
      validator: widget.validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Input field with add button
                Expanded(
                  child: Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: widget.hint,
                              hintStyle: context.bodySmall.copyWith(
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                              ),
                            ),
                            onSubmitted: (_) => _addItem(),
                          ),
                        ),
                        IconButton(
                          onPressed: _addItem,
                          icon: SvgPicture.asset(
                            AppAssets.icons.add,
                            width: 24.w,
                            height: 24.h,
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.selectedItems.isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  // Selected chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.selectedItems.map((item) {
                          return Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: SelectableChip(
                              label: item,
                              isSelected: true,
                              onTap: () => _removeItem(item),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (state.hasError) ...[
              SizedBox(height: 8.h),
              Text(
                state.errorText!,
                style: context.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
    );
  }
}

class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            label,
            style: context.bodySmall.copyWith(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
