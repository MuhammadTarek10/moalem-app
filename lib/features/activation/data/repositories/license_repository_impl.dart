import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/services/secure_storage_service.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/core/utils/license_checker.dart';
import 'package:moalem/features/activation/data/datasources/license_remote_data_source.dart';
import 'package:moalem/features/activation/domain/repositories/license_repository.dart';
import 'package:moalem/features/auth/data/models/coupon_model.dart';

@LazySingleton(as: LicenseRepository)
class LicenseRepositoryImpl implements LicenseRepository {
  final LicenseRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final SecureStorageService _secureStorageService;

  LicenseRepositoryImpl(
    this._remoteDataSource,
    this._storageService,
    this._secureStorageService,
  );

  @override
  Future<CouponModel> redeemCoupon(String code) async {
    final couponModel = await _remoteDataSource.redeemCoupon(code);

    // Store the license in secure storage
    if (couponModel.license != null) {
      await _secureStorageService.write(
        key: AppKeys.license,
        value: couponModel.license,
      );
    }

    // Store the expiration date in regular storage for quick access
    if (couponModel.expiresAt != null) {
      await _storageService.setString(
        AppKeys.licenseExpiresAt,
        couponModel.expiresAt!,
      );
    }

    return couponModel;
  }

  @override
  Future<String?> getLicenseExpiresAt() async {
    return _storageService.getString(AppKeys.licenseExpiresAt);
  }

  @override
  Future<bool> hasValidLicense() async {
    final licenseExpiresAt = await getLicenseExpiresAt();
    return LicenseChecker.isLicenseValid(licenseExpiresAt);
  }
}
