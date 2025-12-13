import 'package:moalem/features/auth/data/models/coupon_model.dart';

abstract class LicenseRepository {
  /// Redeems a coupon code and returns the license details.
  Future<CouponModel> redeemCoupon(String code);

  /// Gets the stored license expiration date.
  Future<String?> getLicenseExpiresAt();

  /// Checks if the user has a valid license.
  Future<bool> hasValidLicense();
}
