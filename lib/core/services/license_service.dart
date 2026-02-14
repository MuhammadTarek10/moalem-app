import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/services/storage_service.dart';

/// Service responsible for managing license validity and expiration monitoring.
@singleton
class LicenseService {
  final StorageService _storageService;
  Timer? _expirationTimer;

  // Stream controller to broadcast expiration events
  final _expirationController = StreamController<void>.broadcast();
  Stream<void> get onLicenseExpired => _expirationController.stream;

  LicenseService(this._storageService);

  /// Initializes the service and starts monitoring if a license exists.
  void init() {
    _checkAndScheduleExpiration();
  }

  /// Checks if the current license is valid.
  bool get isLicenseValid {
    final expiresAtStr = _storageService.getString(AppKeys.licenseExpiresAt);
    if (expiresAtStr == null || expiresAtStr.isEmpty) {
      return false; // No license = invalid (or handle as needed based on business logic)
    }

    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) {
      return false;
    }

    return expiresAt.isAfter(DateTime.now());
  }

  /// Returns the expiration date if one exists.
  DateTime? get expirationDate {
    final expiresAtStr = _storageService.getString(AppKeys.licenseExpiresAt);
    if (expiresAtStr == null) return null;
    return DateTime.tryParse(expiresAtStr);
  }

  /// Updates the license information and restarts monitoring.
  Future<void> updateLicense(String expiresAt) async {
    await _storageService.setString(AppKeys.licenseExpiresAt, expiresAt);
    _checkAndScheduleExpiration();
  }

  /// Clears license data and stops monitoring.
  Future<void> clearLicense() async {
    await _storageService.remove(AppKeys.licenseExpiresAt);
    _cancelTimer();
  }

  void _checkAndScheduleExpiration() {
    _cancelTimer();

    final expiresAtStr = _storageService.getString(AppKeys.licenseExpiresAt);
    if (expiresAtStr == null || expiresAtStr.isEmpty) return;

    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return;

    final now = DateTime.now();
    if (expiresAt.isBefore(now)) {
      // Already expired
      _expirationController.add(null);
    } else {
      // Schedule timer
      final duration = expiresAt.difference(now);
      // Schedule timer for expiration
      _expirationTimer = Timer(duration, () {
        _expirationController.add(null);
      });
    }
  }

  void _cancelTimer() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }

  @disposeMethod
  void dispose() {
    _cancelTimer();
    _expirationController.close();
  }
}
