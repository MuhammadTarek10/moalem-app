import 'package:injectable/injectable.dart';
import 'package:moalem/core/exceptions.dart';
import 'package:moalem/core/services/api_service.dart';
import 'package:moalem/features/auth/data/models/coupon_model.dart';
import 'package:moalem/features/auth/data/models/coupon_request.dart';

abstract class LicenseRemoteDataSource {
  Future<CouponModel> redeemCoupon(String code);
}

@LazySingleton(as: LicenseRemoteDataSource)
class LicenseRemoteDataSourceImpl implements LicenseRemoteDataSource {
  final ApiService _apiService;

  LicenseRemoteDataSourceImpl(this._apiService);

  @override
  Future<CouponModel> redeemCoupon(String code) async {
    final response = await _apiService.applyCoupon(CouponRequest(code: code));
    if (response.data != null) {
      return response.data!;
    }
    throw ServerException(response.message, response.status);
  }
}
