import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../database/notification_database_service.dart';
import '../database/settings_database_service.dart';
import '../models/app_notification_model.dart';

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

  /// Whether today's attendance is marked as Izin (disables check-in).
  bool get hasIzinToday {
    if (_todayAttendance != null &&
        (_todayAttendance!.status ?? '').toLowerCase() == 'izin') {
      return true;
    }
    // Fallback: check history list for today's date
    final todayStr = _formatDate(DateTime.now());
    return _historyList.any((item) =>
        item.attendanceDate == todayStr &&
        (item.status ?? '').toLowerCase() == 'izin');
  }

  /// Whether the user has performed Absen Masuk today.
  bool get hasCheckedIn {
    if (hasIzinToday) return false;
    final time = _todayAttendance?.checkInTime?.trim();
    return time != null &&
        time.isNotEmpty &&
        time != '-' &&
        time.toLowerCase() != 'null';
  }

  /// Whether the user has performed Absen Pulang today.
  bool get hasCheckedOut {
    final time = _todayAttendance?.checkOutTime?.trim();
    return time != null &&
        time.isNotEmpty &&
        time != '-' &&
        time.toLowerCase() != 'null';
  }

  /// Whether conditions allow auto-checkout to execute today:
  /// - Auto-checkout setting is enabled
  /// - CASE 1: User is NOT in Izin status today (disabled the whole day if Izin)
  /// - CASE 2: User MUST have performed Absen Masuk today (must not run if user skipped check-in / absent)
  /// - User has NOT already checked out today
  /// - Attendance record belongs to today's date
  bool get canAutoCheckOutToday {
    if (!_autoCheckOutEnabled) return false;
    if (hasIzinToday) return false;
    if ((_todayAttendance?.status ?? '').toLowerCase() == 'izin') return false;

    final todayStr = _formatDate(DateTime.now());
    if (_todayAttendance == null || _todayAttendance!.attendanceDate != todayStr) {
      return false;
    }

    return hasCheckedIn && !hasCheckedOut;
  }

  /// Returns the UI display status based on check-in time.
  /// 'Hadir' if time <= 08:00, 'Terlambat' if after 08:00.
  String getAttendanceDisplayStatus([DateTime? checkInTime]) {
    if (checkInTime != null) {
      if (checkInTime.hour < 8 ||
          (checkInTime.hour == 8 && checkInTime.minute == 0)) {
        return 'Hadir';
      }
      return 'Terlambat';
    }

    final status = (_todayAttendance?.status ?? '').toLowerCase();
    if (status == 'terlambat') return 'Terlambat';
    if (status == 'masuk' && _todayAttendance?.checkInTime == null) return 'Hadir';

    // Parse check-in time from today's attendance if available
    if (_todayAttendance?.checkInTime != null &&
        _todayAttendance!.checkInTime!.isNotEmpty) {
      try {
        final parts = _todayAttendance!.checkInTime!.split(':');
        if (parts.length >= 2) {
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          if (h > 8 || (h == 8 && m > 0)) {
            return 'Terlambat';
          }
          return 'Hadir';
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    if (now.hour < 8 || (now.hour == 8 && now.minute == 0)) {
      return 'Hadir';
    }
    return 'Terlambat';
  }

  // ── Auto Check-Out ──────────────────────────────────────────────────────

  Timer? _autoCheckOutTimer;
  bool _autoCheckOutEnabled = false;
  bool get autoCheckOutEnabled => _autoCheckOutEnabled;
  bool _isAutoCheckingOut = false;

  static const String _autoCheckOutKey = 'auto_checkout_enabled';

  /// Initialize auto-checkout setting from SQLite (SQFlite).
  Future<void> initAutoCheckOut() async {
    final saved = await SettingsDatabaseService.instance.getBool(_autoCheckOutKey);
    _autoCheckOutEnabled = saved ?? false;
    notifyListeners();
    if (_autoCheckOutEnabled) {
      _scheduleAutoCheckOut();
    }
  }

  /// Toggle auto-checkout and persist the setting in SQLite.
  Future<void> setAutoCheckOut(bool enabled) async {
    _autoCheckOutEnabled = enabled;
    await SettingsDatabaseService.instance.setBool(_autoCheckOutKey, enabled);
    notifyListeners();

    if (enabled) {
      _scheduleAutoCheckOut();
    } else {
      _autoCheckOutTimer?.cancel();
      _autoCheckOutTimer = null;
    }
  }

  /// Schedules a periodic timer that checks if auto-checkout should fire.
  void _scheduleAutoCheckOut() {
    _autoCheckOutTimer?.cancel();
    // Check every 30 seconds for the 16:00 mark
    _autoCheckOutTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAndAutoCheckOut(),
    );
    // Also run an immediate check
    _checkAndAutoCheckOut();
  }

  /// Performs auto-checkout if conditions are met:
  /// - Auto-checkout enabled
  /// - Current time >= 16:00
  /// - CASE 1: User is NOT in Izin status today (disabled the whole day if Izin)
  /// - CASE 2: User MUST have performed Absen Masuk today (does not run if absent / skipped class)
  /// - User has not checked out yet today
  Future<void> _checkAndAutoCheckOut() async {
    if (!_autoCheckOutEnabled || _isAutoCheckingOut) return;

    // CASE 1: If user is on Izin status today, auto-checkout is completely disabled the whole day
    if (hasIzinToday || (_todayAttendance?.status ?? '').toLowerCase() == 'izin') {
      log('Auto check-out disabled: User is in Izin status today');
      return;
    }

    final now = DateTime.now();
    if (now.hour < 16) return;

    final todayStr = _formatDate(now);

    // If _todayAttendance is missing or from a previous day, fetch today's data first
    if (_todayAttendance == null || _todayAttendance!.attendanceDate != todayStr) {
      await fetchToday();
    }

    // CASE 2: Ensure user performed Absen Masuk today (skipped class will not count/run)
    if (!canAutoCheckOutToday) {
      log('Auto check-out skipped: canAutoCheckOutToday is false (hasCheckedIn=$hasCheckedIn, hasCheckedOut=$hasCheckedOut, hasIzinToday=$hasIzinToday)');
      return;
    }

    _isAutoCheckingOut = true;
    try {
      log('Auto check-out triggered at ${_formatTime(now)}');
      await _performAutoCheckOut();
    } finally {
      _isAutoCheckingOut = false;
    }
  }

  Future<void> _performAutoCheckOut() async {
    // Defense-in-depth: verify conditions before calling API
    if (!canAutoCheckOutToday) {
      log('Auto check-out aborted: canAutoCheckOutToday is false');
      return;
    }

    // For auto-checkout we use the office location as fallback
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final timeStr = _formatTime(now);

    final lat = _currentPosition?.latitude ?? AppConstants.officeLatitude;
    final lng = _currentPosition?.longitude ?? AppConstants.officeLongitude;
    final address = _currentPosition != null
        ? _currentAddress
        : 'Auto checkout - ${AppConstants.officeName}';

    try {
      final response = await _attendanceService.checkOut({
        'attendance_date': dateStr,
        'check_out': timeStr,
        'check_out_lat': lat.toString(),
        'check_out_lng': lng.toString(),
        'check_out_location': '$lat, $lng',
        'check_out_address': address,
      });

      final data = response.data;
      if (data is Map && data['data'] != null) {
        _todayAttendance = AttendanceModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      log('Auto check-out successful');
      await fetchStats();

      // Record auto-checkout event into SQFlite notifications
      try {
        await NotificationDatabaseService.instance.insertNotification(
          AppNotificationModel(
            title: 'Auto Absen Pulang Berhasil',
            message:
                'Presensi pulang otomatis dicatat pada $timeStr WIB di ${AppConstants.officeName}.',
            type: 'check_out',
            timestamp: DateTime.now(),
          ),
        );
      } catch (e) {
        log('Auto check-out notification error: $e');
      }

      notifyListeners();
    } catch (e) {
      log('Auto check-out failed: $e');
    }
  }

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
      if (_autoCheckOutEnabled) {
        _checkAndAutoCheckOut();
      }
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

  /// Fetches attendance history for an entire month (from 1st to last day).
  Future<void> fetchHistoryForMonth(DateTime month) {
    final start =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final end =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    return fetchHistory(start: start, end: end);
  }

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
    final isLate = now.hour > 8 || (now.hour == 8 && now.minute > 0);
    final statusPayload = isLate ? 'terlambat' : 'masuk';

    try {
      final response = await _attendanceService.checkIn({
        'attendance_date': dateStr,
        'check_in': timeStr,
        'check_in_lat': _currentPosition!.latitude,
        'check_in_lng': _currentPosition!.longitude,
        'check_in_address': _currentAddress,
        'status': statusPayload,
      });

      // Schedule auto-checkout if enabled
      if (_autoCheckOutEnabled) {
        _scheduleAutoCheckOut();
      }

      final data = response.data;
      if (data is Map && data['data'] != null) {
        final model = AttendanceModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        _todayAttendance = isLate && (model.status ?? '').toLowerCase() != 'terlambat'
            ? AttendanceModel(
                id: model.id,
                userId: model.userId,
                attendanceDate: model.attendanceDate,
                checkInTime: model.checkInTime ?? timeStr,
                checkOutTime: model.checkOutTime,
                checkInLat: model.checkInLat,
                checkInLng: model.checkInLng,
                checkOutLat: model.checkOutLat,
                checkOutLng: model.checkOutLng,
                checkInAddress: model.checkInAddress,
                checkOutAddress: model.checkOutAddress,
                checkInLocation: model.checkInLocation,
                checkOutLocation: model.checkOutLocation,
                status: 'terlambat',
                alasanIzin: model.alasanIzin,
              )
            : model;
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
    if (hasIzinToday) {
      _errorMessage = 'Anda sedang dalam status Izin hari ini.';
      notifyListeners();
      return false;
    }

    if (!hasCheckedIn) {
      _errorMessage = 'Anda belum melakukan absen masuk hari ini.';
      notifyListeners();
      return false;
    }

    if (hasCheckedOut) {
      _errorMessage = 'Anda sudah melakukan absen keluar hari ini.';
      notifyListeners();
      return false;
    }

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
        if (dateStr == _formatDate(DateTime.now())) {
          _todayAttendance = newRecord;
        }
      } else if (dateStr == _formatDate(DateTime.now())) {
        _todayAttendance = AttendanceModel(
          attendanceDate: dateStr,
          status: 'izin',
          alasanIzin: reason,
        );
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
