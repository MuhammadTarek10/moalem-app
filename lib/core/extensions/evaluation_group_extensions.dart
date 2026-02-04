import 'package:easy_localization/easy_localization.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_strings.dart';

extension EvaluationGroupExtension on EvaluationGroup {
  String get stageName {
    switch (this) {
      case EvaluationGroup.prePrimary:
        return AppStrings.prePrimaryGroup.tr();
      case EvaluationGroup.primary:
        return AppStrings.primaryGroup.tr();
      case EvaluationGroup.secondary:
        return AppStrings.secondaryGroup.tr();
      case EvaluationGroup.high:
        return AppStrings.highSchoolGroup.tr();
    }
  }
}
