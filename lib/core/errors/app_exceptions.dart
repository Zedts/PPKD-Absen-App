/// Custom exceptions for structured error handling across the app.
library;

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thrown when the server returns a validation error (422).
class ValidationException extends AppException {
  final Map<String, List<String>> errors;

  const ValidationException(
    super.message, {
    this.errors = const {},
    super.statusCode = 422,
  });
}

/// Thrown when authentication fails (401).
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Sesi telah berakhir. Silakan login kembali.',
  ]) : super(statusCode: 401);
}

/// Thrown when a resource is not found (404).
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Data tidak ditemukan.',
  ]) : super(statusCode: 404);
}

/// Thrown when there's a conflict (409).
class ConflictException extends AppException {
  const ConflictException(super.message) : super(statusCode: 409);
}

/// Thrown when there's no internet connection.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Tidak ada koneksi internet.',
  ]);
}
