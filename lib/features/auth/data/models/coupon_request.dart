import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon_request.freezed.dart';
part 'coupon_request.g.dart';

@freezed
abstract class CouponRequest with _$CouponRequest {
  const factory CouponRequest({required String code}) = _CouponRequest;

  factory CouponRequest.fromJson(Map<String, dynamic> json) =>
      _$CouponRequestFromJson(json);
}
