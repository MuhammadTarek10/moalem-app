import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/extensions/context.dart';

class InputLabel extends StatelessWidget {
  const InputLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.bodySmall.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    this.keyboardType,
    this.label,
    this.hint,
    required this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: context.bodySmall.copyWith(color: Colors.black),
        hintText: hint,
        hintStyle: context.bodySmall.copyWith(color: Colors.grey),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
