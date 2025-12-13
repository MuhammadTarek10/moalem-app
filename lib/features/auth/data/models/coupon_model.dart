import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon_model.freezed.dart';
part 'coupon_model.g.dart';

@freezed
abstract class CouponModel with _$CouponModel {
  const factory CouponModel({
    @JsonKey(name: 'license') String? license,
    @JsonKey(name: 'expiresAt') String? expiresAt,
  }) = _CouponModel;

  factory CouponModel.fromJson(Map<String, dynamic> json) =>
      _$CouponModelFromJson(json);
}
