/// Utility class to check if a user's license is valid.
class LicenseChecker {
  /// Checks if the license expiration date is valid (not null and in the future).
  ///
  /// Returns `true` if the license is valid, `false` otherwise.
  static bool isLicenseValid(String? licenseExpiresAt) {
    if (licenseExpiresAt == null || licenseExpiresAt.isEmpty) {
      return false;
    }

    final expiresAt = DateTime.tryParse(licenseExpiresAt);
    if (expiresAt == null) {
      return false;
    }

    return expiresAt.isAfter(DateTime.now());
  }

  /// Returns the remaining days until the license expires.
  ///
  /// Returns `null` if the license is invalid or already expired.
  static int? getRemainingDays(String? licenseExpiresAt) {
    if (licenseExpiresAt == null || licenseExpiresAt.isEmpty) {
      return null;
    }

    final expiresAt = DateTime.tryParse(licenseExpiresAt);
    if (expiresAt == null) {
      return null;
    }

    final now = DateTime.now();
    if (expiresAt.isBefore(now)) {
      return null;
    }

    return expiresAt.difference(now).inDays;
  }
}
