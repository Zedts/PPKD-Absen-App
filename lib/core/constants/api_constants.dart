/// Central location for all API-related constants.
/// Change [baseUrl] here to point the entire app at a different server.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://appabsensi.mobileprojp.com';

  // Auth
  static const String login = '/api/login';
  static const String register = '/api/register';
  static const String forgotPassword = '/api/forgot-password';
  static const String resetPassword = '/api/reset-password';

  // Attendance
  static const String checkIn = '/api/absen/check-in';
  static const String checkOut = '/api/absen/check-out';
  static const String absenToday = '/api/absen/today';
  static const String absenStats = '/api/absen/stats';
  static const String absenHistory = '/api/absen/history';
  static const String deleteAbsen = '/api/absen/{id}';

  // Izin
  static const String izin = '/api/izin';

  // Profile
  static const String profile = '/api/profile';

  // Trainings & Batches
  static const String trainings = '/api/trainings';
  static const String batches = '/api/batches';

  // Device
  static const String deviceToken = '/api/device-token';
}
