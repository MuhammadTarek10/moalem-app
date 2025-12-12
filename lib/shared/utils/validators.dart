import 'package:easy_localization/easy_localization.dart';
import 'package:moalem/core/constants/app_strings.dart';

String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return AppStrings.requiredField.tr();
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return AppStrings.invalidEmail.tr();
  }

  return null;
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return AppStrings.requiredField.tr();
  }

  if (value.length < 6) {
    return AppStrings.passwordTooShort.tr();
  }
  return null;
}

String? confirmPasswordValidator(String? value, String password) {
  if (value == null || value.isEmpty) {
    return AppStrings.requiredField.tr();
  }

  if (value.length < 6) {
    return AppStrings.passwordTooShort.tr();
  }

  if (value != password) {
    return AppStrings.confirmPasswordMismatch.tr();
  }
  return null;
}

String? requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.requiredField.tr();
  }
  return null;
}

String? listValidator(List<String>? value) {
  if (value == null || value.isEmpty) {
    return AppStrings.requiredField.tr();
  }
  return null;
}

String? phoneNumberValidator(String? value) {
  if (value == null || value.isEmpty) {
    return AppStrings.requiredField.tr();
  }
  if (!RegExp(r'^01\d{9}$').hasMatch(value) || value.length != 11) {
    return AppStrings.invalidPhoneNumber.tr();
  }
  return null;
}
