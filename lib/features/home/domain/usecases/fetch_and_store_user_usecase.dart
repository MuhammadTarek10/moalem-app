import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/services/secure_storage_service.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/core/utils/license_checker.dart';
import 'package:moalem/features/auth/data/models/user_mapper.dart';
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

  /// Returns true if the user's license is valid, false otherwise.
  Future<bool> call() async {
    try {
      // Fetch user from API
      final user = await _userRepository.getUser();

      // Store user data in secure storage
      final userModel = user.toModel();
      await _secureStorage.write(
        key: AppKeys.user,
        value: jsonEncode(userModel.toJson()),
      );

      // Update license expiration in regular storage for quick access
      if (user.licenseExpiresAt != null) {
        await _storage.setString(
          AppKeys.licenseExpiresAt,
          user.licenseExpiresAt!,
        );
      }

      // Check if license is still valid
      return LicenseChecker.isLicenseValid(user.licenseExpiresAt);
    } catch (e) {
      // If fetching fails, check local storage
      final licenseExpiresAt = _storage.getString(AppKeys.licenseExpiresAt);
      return LicenseChecker.isLicenseValid(licenseExpiresAt);
    }
  }
}
