import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/extensions/context.dart';

class DropdownField extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.validator,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return FormField<String>(
        initialValue: value,
        validator: validator,
        builder: (FormFieldState<String> state) {
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _showCupertinoPicker(context);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: context.bodySmall.copyWith(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    errorText: state.errorText,
                    suffixIcon: const Icon(Icons.keyboard_arrow_down),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                  ),
                  isEmpty: value == null,
                  child: value != null
                      ? Text(
                          value!,
                          style: context.bodySmall.copyWith(
                            color: Colors.black,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          );
        },
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.bodySmall.copyWith(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }

  void _showCupertinoPicker(BuildContext context) {
    if (items.isEmpty) return;

    final int initialIndex = value != null ? items.indexOf(value!) : 0;
    int selectedIndex = initialIndex >= 0 ? initialIndex : 0;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250.h,
          padding: EdgeInsets.only(top: 6.h),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        onChanged(items[selectedIndex]);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32.h,
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    onSelectedItemChanged: (int index) {
                      selectedIndex = index;
                    },
                    children: items.map((item) {
                      return Center(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
