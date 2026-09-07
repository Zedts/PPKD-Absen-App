import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../errors/app_exceptions.dart';
import '../models/user_model.dart';
import '../services/dio_client.dart';
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/image_picker_helper.dart';

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
        final incoming = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        String? photo = incoming.profilePhoto;
        if (photo != null && photo.trim().isNotEmpty) {
          photo = ImagePickerHelper.normalizePhotoUrl(photo);
          await storage.saveProfilePhoto(photo);
        } else {
          // If backend GET /api/profile omitted photo, check if local storage has one
          final localPhoto = await storage.getProfilePhoto();
          if (localPhoto != null && localPhoto.trim().isNotEmpty) {
            photo = localPhoto;
          } else {
            photo = null;
          }
        }

        final bool shouldClear = (photo == null || photo.trim().isEmpty);
        _user = incoming.copyWith(
          profilePhoto: photo,
          clearProfilePhoto: shouldClear,
        );
        await storage.saveUserInfo(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          profilePhoto: photo,
        );
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
        final incoming = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        final currentPhoto = _user?.profilePhoto ?? await storage.getProfilePhoto();
        _user = incoming.copyWith(profilePhoto: currentPhoto);
        await storage.saveUserInfo(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          profilePhoto: currentPhoto,
        );
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
      final response = await _profileService.updateProfilePhoto({
        'profile_photo': base64Photo,
      });

      String? newPhotoUrl;
      final data = response.data;
      if (data is Map && data['data'] is Map && data['data']['profile_photo'] != null) {
        newPhotoUrl = data['data']['profile_photo'].toString();
      }

      // If backend returned a photo URL, normalize it; otherwise fall back to base64Photo
      final resolvedPhoto = (newPhotoUrl != null && newPhotoUrl.trim().isNotEmpty)
          ? ImagePickerHelper.normalizePhotoUrl(newPhotoUrl)
          : base64Photo;

      // Persist immediately in secure storage
      await storage.saveProfilePhoto(resolvedPhoto);

      // Update local state immediately so UI updates instantly
      if (_user != null) {
        _user = _user!.copyWith(profilePhoto: resolvedPhoto);
        await storage.saveUserInfo(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          profilePhoto: resolvedPhoto,
        );
      } else {
        _user = UserModel(id: 0, name: 'Peserta', email: '', profilePhoto: resolvedPhoto);
      }
      notifyListeners();

      // Attempt background profile sync without losing the photo
      try {
        final profileResp = await _profileService.getProfile();
        final pData = profileResp.data;
        if (pData is Map && pData['data'] != null) {
          final incoming = UserModel.fromJson(pData['data'] as Map<String, dynamic>);
          _user = incoming.copyWith(profilePhoto: resolvedPhoto);
        }
      } catch (_) {
        // Ignored
      }

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

  // ── Delete Profile Photo ───────────────────────────────────────────────

  Future<bool> deleteProfilePhoto() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Attempt sending empty photo payload to backend
      try {
        await _profileService.updateProfilePhoto({
          'profile_photo': '',
        });
      } catch (_) {
        // Backend may reject empty string; still proceed to clear locally
      }

      // 2. Clear locally from secure storage
      await storage.clearProfilePhoto();

      // 3. Update in-memory user
      if (_user != null) {
        _user = _user!.copyWith(clearProfilePhoto: true);
        await storage.saveUserInfo(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          profilePhoto: null,
        );
      }
      return true;
    } catch (_) {
      _errorMessage = 'Gagal menghapus foto profil.';
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
