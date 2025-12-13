import 'package:injectable/injectable.dart';
import 'package:moalem/features/activation/domain/repositories/license_repository.dart';
import 'package:moalem/features/auth/data/models/coupon_model.dart';

@injectable
class RedeemCouponUseCase {
  final LicenseRepository _repository;

  RedeemCouponUseCase(this._repository);

  Future<CouponModel> call(String code) {
    return _repository.redeemCoupon(code);
  }
}
