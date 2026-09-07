import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/app_exceptions.dart';
import 'secure_storage_service.dart';

/// Configures a [Dio] instance with base URL, interceptors for auth token
/// injection, and structured error mapping.
class DioClient {
  final SecureStorageService _storage;
  late final Dio dio;

  DioClient(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          final exception = _mapDioError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: exception,
              type: error.type,
              response: error.response,
            ),
          );
        },
      ),
    );
  }

  /// Maps [DioException] to our custom [AppException] hierarchy.
  AppException _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkException('Koneksi timeout. Coba lagi.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = error.response;
    if (response == null) {
      return const AppException('Terjadi kesalahan. Coba lagi.');
    }

    final data = response.data;
    final message = data is Map ? (data['message'] as String? ?? '') : '';

    switch (response.statusCode) {
      case 401:
        return UnauthorizedException(
          message.isNotEmpty ? message : 'Sesi telah berakhir.',
        );
      case 404:
        return NotFoundException(
          message.isNotEmpty ? message : 'Data tidak ditemukan.',
        );
      case 409:
        return ConflictException(
          message.isNotEmpty ? message : 'Data sudah ada.',
        );
      case 422:
        final errors = <String, List<String>>{};
        if (data is Map && data['errors'] is Map) {
          (data['errors'] as Map).forEach((key, value) {
            errors[key.toString()] = (value as List)
                .map((e) => e.toString())
                .toList();
          });
        }
        return ValidationException(
          message.isNotEmpty ? message : 'Data tidak valid.',
          errors: errors,
        );
      default:
        return AppException(
          message.isNotEmpty ? message : 'Terjadi kesalahan server.',
          statusCode: response.statusCode,
        );
    }
  }
}
