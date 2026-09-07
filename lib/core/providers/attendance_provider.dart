import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../models/attendance_model.dart';
import '../models/attendance_stats_model.dart';
import '../services/attendance_service.dart';
import '../services/dio_client.dart';

/// Manages GPS location, radius calculation, attendance check-in/out,
/// history, and permit (izin) requests.
class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService;

  AttendanceProvider({
    required DioClient dioClient,
  }) : _attendanceService = AttendanceService(dioClient.dio);

  // ── State ──────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Today & Stats
  AttendanceModel? _todayAttendance;
  AttendanceModel? get todayAttendance => _todayAttendance;

  AttendanceStatsModel? _stats;
  AttendanceStatsModel? get stats => _stats;

  List<AttendanceModel> _historyList = [];
  List<AttendanceModel> get historyList => _historyList;

  List<AttendanceModel> get izinList =>
      _historyList.where((item) => item.status == 'izin').toList();

  // Location & Geofencing
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  String _currentAddress = 'Mencari lokasi...';
  String get currentAddress => _currentAddress;

  double _distanceToOffice = 0.0;
  double get distanceToOffice => _distanceToOffice;

  bool get isWithinRadius =>
      _distanceToOffice <= AppConstants.maxAttendanceRadiusMeters;

  bool _isLocationLoading = false;
  bool get isLocationLoading => _isLocationLoading;

  String? _locationError;
  String? get locationError => _locationError;

  final LatLng officeLocation = const LatLng(
    AppConstants.officeLatitude,
    AppConstants.officeLongitude,
  );

  // ── Geofencing & Location Methods ──────────────────────────────────────

  /// Checks GPS service and permissions, then fetches the current position.
  Future<void> checkPermissionsAndGetLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentAddress = 'Layanan GPS/lokasi dinonaktifkan.';
        _locationError = 'Aktifkan GPS perangkat Anda.';
        _isLocationLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentAddress = 'Izin akses lokasi ditolak.';
          _locationError = 'Izin lokasi dibutuhkan untuk presensi.';
          _isLocationLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentAddress = 'Izin lokasi ditolak permanen.';
        _locationError = 'Buka Pengaturan untuk mengizinkan lokasi.';
        _isLocationLoading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentPosition = position;

      // Calculate distance to target office in meters
      _distanceToOffice = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        AppConstants.officeLatitude,
        AppConstants.officeLongitude,
      );

      log('Location: ${position.latitude}, ${position.longitude} | Distance: $_distanceToOffice m');

      // Reverse geocode address
      await _getAddressFromLatLng(position);
    } catch (e) {
      log('Error getting location: $e');
      _currentAddress = 'Gagal memuat alamat GPS.';
      _locationError = 'Gagal mendapatkan koordinat GPS.';
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final postalCode = place.postalCode ?? '';

        final parts = [street, subLocality, locality, postalCode]
            .where((p) => p.trim().isNotEmpty)
            .toList();

        _currentAddress = parts.isNotEmpty ? parts.join(', ') : 'Lokasi Terdeteksi';
      }
    } catch (e) {
      log('Reverse geocoding error: $e');
      _currentAddress = 'Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }

  // ── Today & Stats API ──────────────────────────────────────────────────

  Future<void> fetchToday({String? date}) async {
    final targetDate = date ?? _formatDate(DateTime.now());
    try {
      final response = await _attendanceService.getTodayAbsen(targetDate);
      final data = response.data;
      if (data is Map && data['data'] != null) {
        _todayAttendance = AttendanceModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      } else {
        _todayAttendance = null;
      }
    } on DioException {
      _todayAttendance = null;
    } catch (_) {
      _todayAttendance = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchStats({String? start, String? end}) async {
    final now = DateTime.now();
    final firstDay = start ?? _formatDate(DateTime(now.year, now.month, 1));
    final lastDay = end ?? _formatDate(DateTime(now.year, now.month + 1, 0));

    try {
      final response = await _attendanceService.getStats(firstDay, lastDay);
      final data = response.data;
      if (data is Map && data['data'] != null) {
        _stats = AttendanceStatsModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Keep previous stats
    } finally {
      notifyListeners();
    }
  }

  // ── History API ────────────────────────────────────────────────────────

  Future<void> fetchHistory({String? start, String? end}) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final response = await _attendanceService.getHistory(
        start: start,
        end: end,
      );
      final data = response.data;
      if (data is Map && data['data'] is List) {
        final list = (data['data'] as List)
            .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sort descending by attendanceDate
        list.sort((a, b) => (b.attendanceDate ?? '').compareTo(a.attendanceDate ?? ''));
        _historyList = list;
      } else {
        _historyList = [];
      }
    } on DioException catch (e) {
      _handleError(e);
    } catch (_) {
      _errorMessage = 'Gagal memuat riwayat presensi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Attendance Actions (Check-In / Check-Out) ──────────────────────────

  Future<bool> checkIn() async {
    if (!isWithinRadius) {
      _errorMessage = 'Anda berada di luar radius absensi (jarak: ${_formatDistance(_distanceToOffice)}, maks: 500 m).';
      notifyListeners();
      return false;
    }

    if (_currentPosition == null) {
      _errorMessage = 'Lokasi belum ditemukan. Tunggu hingga GPS aktif.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final timeStr = _formatTime(now);

    try {
      final response = await _attendanceService.checkIn({
        'attendance_date': dateStr,
        'check_in': timeStr,
        'check_in_lat': _currentPosition!.latitude,
        'check_in_lng': _currentPosition!.longitude,
        'check_in_address': _currentAddress,
        'status': 'masuk',
      });

      final data = response.data;
      if (data is Map && data['data'] != null) {
        _todayAttendance = AttendanceModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      await fetchStats();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Gagal melakukan absen masuk.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkOut() async {
    if (!isWithinRadius) {
      _errorMessage =
          'Anda berada di luar radius absensi (jarak: ${_formatDistance(_distanceToOffice)}, maks: 500 m).';
      notifyListeners();
      return false;
    }

    if (_currentPosition == null) {
      _errorMessage = 'Lokasi belum ditemukan. Tunggu hingga GPS aktif.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final timeStr = _formatTime(now);

    try {
      final response = await _attendanceService.checkOut({
        'attendance_date': dateStr,
        'check_out': timeStr,
        'check_out_lat': _currentPosition!.latitude.toString(),
        'check_out_lng': _currentPosition!.longitude.toString(),
        'check_out_location':
            '${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        'check_out_address': _currentAddress,
      });

      final data = response.data;
      if (data is Map && data['data'] != null) {
        _todayAttendance = AttendanceModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      await fetchStats();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Gagal melakukan absen keluar.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Submit Izin ────────────────────────────────────────────────────────

  Future<bool> submitIzin({
    required DateTime date,
    required String reason,
  }) async {
    _setLoading(true);
    _clearError();

    final dateStr = _formatDate(date);

    try {
      final response = await _attendanceService.submitIzin({
        'date': dateStr,
        'alasan_izin': reason,
      });

      final data = response.data;
      if (data is Map && data['data'] != null) {
        final newRecord = AttendanceModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        _historyList.removeWhere((item) => item.attendanceDate == dateStr);
        _historyList.insert(0, newRecord);
      }

      await fetchStats();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengajukan permohonan izin.';
      return false;
    } finally {
      _setLoading(false);
    }
  }


  // ── Helpers ────────────────────────────────────────────────────────────

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
    } else if (e.response?.data is Map && e.response?.data['message'] != null) {
      _errorMessage = e.response?.data['message'].toString();
    } else {
      _errorMessage = 'Terjadi kesalahan pada server.';
    }
    notifyListeners();
  }
}
