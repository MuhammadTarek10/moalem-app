import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/core/services/license_service.dart';
import 'package:moalem/core/services/secure_storage_service.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/core/utils/license_checker.dart';
import 'package:moalem/features/auth/data/models/user_mapper.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';

@injectable
class FetchAndStoreUserUseCase {
  final UserRepository _userRepository;
  final SecureStorageService _secureStorage;
  final StorageService _storage;

  FetchAndStoreUserUseCase(
    this._userRepository,
    this._secureStorage,
    this._storage,
  );

  /// Returns the User object.
  Future<User> call() async {
    try {
      // Fetch user from API
      var user = await _userRepository.getUser();

      // Check if we have a locally stored valid license that might be newer than the API result
      // This handles the race condition where the API returns stale data immediately after activation
      final localLicenseExpiresAt = _storage.getString(
        AppKeys.licenseExpiresAt,
      );
      if (LicenseChecker.isLicenseValid(localLicenseExpiresAt)) {
        // If the API returns an invalid license, or even if it returns valid,
        // we trust our local post-activation update if the API one appears invalid/expired
        if (!LicenseChecker.isLicenseValid(user.licenseExpiresAt)) {
          user = user.copyWith(licenseExpiresAt: localLicenseExpiresAt);
        }
      }

      // Store user data in secure storage
      final userModel = user.toModel();
      await _secureStorage.write(
        key: AppKeys.user,
        value: jsonEncode(userModel.toJson()),
      );

      // Update license expiration in regular storage for quick access
      // Only update if the API returns a non-null value
      if (user.licenseExpiresAt != null && user.licenseExpiresAt!.isNotEmpty) {
        if (getIt.isRegistered<LicenseService>()) {
          await getIt<LicenseService>().updateLicense(user.licenseExpiresAt!);
        } else {
          // Fallback if service not found (shouldn't happen)
          await _storage.setString(
            AppKeys.licenseExpiresAt,
            user.licenseExpiresAt!,
          );
        }
      }

      return user;
    } catch (e) {
      // If fetching fails, try to get from local storage
      final userJson = await _secureStorage.read(AppKeys.user);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson)).toDomain();
      }
      rethrow;
    }
  }
}
