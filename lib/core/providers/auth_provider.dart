import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../errors/app_exceptions.dart';
import '../models/auth_response.dart';
import '../models/training_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/dio_client.dart';
import '../services/secure_storage_service.dart';

/// Manages authentication state: login, register, logout, loading, errors,
/// and reference training data for registration.
class AuthProvider extends ChangeNotifier {
  final SecureStorageService storage;
  final AuthService _authService;

  AuthProvider({
    required this.storage,
    required DioClient dioClient,
  }) : _authService = AuthService(dioClient.dio);

  SecureStorageService get _storage => storage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _user;
  UserModel? get user => _user;

  List<TrainingModel> _trainings = defaultTrainings;
  List<TrainingModel> get trainings => _trainings;

  static const List<TrainingModel> defaultTrainings = [
    TrainingModel(id: 1, title: 'Data Management Staff (Operator Komputer)'),
    TrainingModel(id: 2, title: 'Bahasa Inggris'),
    TrainingModel(id: 3, title: 'Desainer Grafis Madya'),
    TrainingModel(id: 4, title: 'Tata Boga'),
    TrainingModel(id: 5, title: 'Tata Busana'),
    TrainingModel(id: 6, title: 'Perhotelan'),
    TrainingModel(id: 7, title: 'Teknisi Komputer'),
    TrainingModel(id: 8, title: 'Teknisi Jaringan'),
    TrainingModel(id: 9, title: 'Barista'),
    TrainingModel(id: 10, title: 'Bahasa Korea'),
    TrainingModel(id: 11, title: 'Make Up Artist'),
    TrainingModel(id: 12, title: 'Desainer Multimedia'),
    TrainingModel(id: 13, title: 'Content Creator'),
    TrainingModel(id: 14, title: 'Web Programming'),
    TrainingModel(id: 15, title: 'Digital Marketing'),
    TrainingModel(id: 16, title: 'Mobile Programming'),
    TrainingModel(id: 17, title: 'Akuntansi Junior'),
    TrainingModel(id: 18, title: 'Konstruksi Bangunan dengan CAD'),
  ];

  // ── Initialise (check existing token and load trainings) ─────────────────

  Future<void> init() async {
    final token = await _storage.getToken();
    _isLoggedIn = token != null;
    if (_isLoggedIn) {
      final name = await _storage.getUserName();
      final email = await _storage.getUserEmail();
      if (name != null && email != null) {
        _user = UserModel(id: 0, name: name, email: email);
      }
    }
    notifyListeners();

    // Fetch live trainings in background
    fetchTrainings();
  }

  // ── Trainings ───────────────────────────────────────────────────────────

  Future<void> fetchTrainings() async {
    try {
      final response = await _authService.getTrainings();
      final data = response.data;
      if (data is Map && data['data'] is List) {
        final list = (data['data'] as List)
            .map((e) => TrainingModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _trainings = list;
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep default fallback trainings on error
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login({
        'email': email,
        'password': password,
      });

      final data = response.data;
      final authData = AuthData.fromJson(data['data'] as Map<String, dynamic>);

      await _saveSession(authData);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String jenisKelamin, // 'L' or 'P'
    required int batchId,
    required int trainingId,
    String profilePhoto = '',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register({
        'name': name,
        'email': email,
        'password': password,
        'jenis_kelamin': jenisKelamin,
        'profile_photo': profilePhoto,
        'batch_id': batchId,
        'training_id': trainingId,
      });

      final data = response.data;
      final authData = AuthData.fromJson(data['data'] as Map<String, dynamic>);

      await _saveSession(authData);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.forgotPassword({'email': email});
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────

  Future<bool> resetPassword(
      String email, String otp, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword({
        'email': email,
        'otp': otp,
        'password': password,
      });
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.clearAll();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<void> _saveSession(AuthData authData) async {
    _user = authData.user;
    await _storage.saveToken(authData.token);
    await _storage.saveUserInfo(
      id: authData.user.id,
      name: authData.user.name,
      email: authData.user.email,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _handleError(DioException e) {
    final error = e.error;
    if (error is AppException) {
      _errorMessage = error.message;
    } else {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
    }
    notifyListeners();
  }
}
