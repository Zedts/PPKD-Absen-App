/// Application-wide constants: storage keys, durations, etc.
class AppConstants {
  AppConstants._();

  // Secure Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';

  // Validation
  static const int minPasswordLength = 8;
  static const Duration debounceDuration = Duration(milliseconds: 500);

  // App Info
  static const String appName = 'Absen PPKD';
}
