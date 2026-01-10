import 'dart:convert';

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

      // Extract expiresAt from the JWT token
      try {
        final expiresAt = _extractExpiresAtFromJWT(couponModel.license!);
        if (expiresAt != null) {
          await _storageService.setString(AppKeys.licenseExpiresAt, expiresAt);
        }
      } catch (e) {
        // If JWT decoding fails, try using the expiresAt from the model
        if (couponModel.expiresAt != null) {
          await _storageService.setString(
            AppKeys.licenseExpiresAt,
            couponModel.expiresAt!,
          );
        }
      }
    } else if (couponModel.expiresAt != null) {
      // Fallback: Store the expiration date from the model if no license token
      await _storageService.setString(
        AppKeys.licenseExpiresAt,
        couponModel.expiresAt!,
      );
    }

    return couponModel;
  }

  /// Extracts the expiresAt field from a JWT token
  String? _extractExpiresAtFromJWT(String token) {
    try {
      // JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];

      // Normalize base64 string (JWT uses base64url encoding without padding)
      var normalizedPayload = payload.replaceAll('-', '+').replaceAll('_', '/');

      // Add padding if needed
      switch (normalizedPayload.length % 4) {
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      // Decode from base64
      final jsonString = utf8.decode(base64.decode(normalizedPayload));

      // Parse JSON
      final Map<String, dynamic> payloadMap = json.decode(jsonString);

      // Extract expiresAt
      return payloadMap['expiresAt'] as String?;
    } catch (e) {
      // Return null if decoding fails
      return null;
    }
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
