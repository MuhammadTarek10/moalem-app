import 'package:easy_localization/easy_localization.dart';
import 'package:moalem/core/entities/failure.dart';

extension FailureExtension on Failure {
  String get messageToDisplay {
    if (this is ClassLimitFailure) {
      return 'class_limit_reached'.tr();
    } else if (this is StudentLimitFailure) {
      return 'student_limit_reached'.tr();
    } else if (this is ServerFailure) {
      return message;
    } else if (this is NetworkFailure) {
      return 'network_error'.tr(); // Make sure this key exists or fallback
    } else if (this is CacheFailure) {
      return 'cache_error'.tr();
    }
    return 'error_message'.tr();
  }
}
