import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../errors/app_exceptions.dart';
import '../models/user_model.dart';
import '../services/dio_client.dart';
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';

/// Manages user profile fetching, updating name, and updating profile photo.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;
  final SecureStorageService storage;

  ProfileProvider({
    required DioClient dioClient,
    required this.storage,
  }) : _profileService = ProfileService(dioClient.dio);

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Fetch Profile ──────────────────────────────────────────────────────

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.getProfile();
      final data = response.data;
      if (data is Map && data['data'] != null) {
        _user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        if (_user != null) {
          await storage.saveUserInfo(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
          );
        }
      }
    } on DioException catch (e) {
      _handleError(e);
    } catch (_) {
      _errorMessage = 'Gagal memuat profil pengguna.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Profile Name ────────────────────────────────────────────────

  Future<bool> updateProfile(String newName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.updateProfile({'name': newName});
      final data = response.data;
      if (data is Map && data['data'] != null) {
        _user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        if (_user != null) {
          await storage.saveUserInfo(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
          );
        }
      }
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Gagal memperbarui profil.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Profile Photo ───────────────────────────────────────────────

  Future<bool> updateProfilePhoto(String base64Photo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.updateProfilePhoto({
        'profile_photo': base64Photo,
      });
      // Refetch profile to get new photo URL
      await fetchProfile();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Gagal memperbarui foto profil.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleError(DioException e) {
    final error = e.error;
    if (error is AppException) {
      _errorMessage = error.message;
    } else if (e.response?.data is Map && e.response?.data['message'] != null) {
      _errorMessage = e.response?.data['message'].toString();
    } else {
      _errorMessage = 'Terjadi kesalahan pada server.';
    }
  }
}
