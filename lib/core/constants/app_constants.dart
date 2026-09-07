/// Application-wide constants: storage keys, durations, office location, and app metadata.
class AppConstants {
  AppConstants._();

  // Secure Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userProfilePhotoKey = 'user_profile_photo';

  // Validation
  static const int minPasswordLength = 8;
  static const Duration debounceDuration = Duration(milliseconds: 500);

  // Office Geofence & Radius
  static const double officeLatitude = -6.210759;
  static const double officeLongitude = 106.812934;
  static const double maxAttendanceRadiusMeters = 500.0;
  static const String officeName = 'PPKD Jakarta Pusat';
  static const String officeAddress =
      'Jl. Karet Pasar Baru Barat No. 23, Karet Tengsin, Tanah Abang, Jakarta Pusat';

  // App Information (Single Source of Truth for Tentang Aplikasi)
  static const String appName = 'Absen PPKD';
  static const String appSubtitle = 'Aplikasi Presensi Pelatihan';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription =
      'Aplikasi Presensi Mandiri berbasis Geofencing GPS untuk peserta pelatihan Pusat Pelatihan Kerja Daerah (PPKD) Jakarta Pusat.';
  static const String appDeveloper = 'Pusat Pelatihan Kerja Daerah Jakarta Pusat';
  static const String appCopyright = '© 2026 PPKD Jakarta Pusat. All Rights Reserved.';
}
