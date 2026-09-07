import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_wavy_header.dart';
import '../../widgets/common/notification_button.dart';
import '../../widgets/common/toast_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;

  final LatLng _officeLatLng = const LatLng(
    AppConstants.officeLatitude,
    AppConstants.officeLongitude,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final attendance = context.read<AttendanceProvider>();
    final profile = context.read<ProfileProvider>();

    attendance.fetchToday();
    attendance.fetchStats();
    profile.fetchProfile();

    await attendance.checkPermissionsAndGetLocation();
    if (mounted && attendance.currentPosition != null && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              attendance.currentPosition!.latitude,
              attendance.currentPosition!.longitude,
            ),
            zoom: 15.5,
          ),
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  Set<Marker> _buildMarkers(AttendanceProvider attendance) {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('office'),
        position: _officeLatLng,
        infoWindow: const InfoWindow(
          title: AppConstants.officeName,
          snippet: 'Area Presensi (Maks. 500 m)',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    if (attendance.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(
            attendance.currentPosition!.latitude,
            attendance.currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Lokasi Anda',
            snippet: attendance.currentAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            attendance.isWithinRadius
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    return {
      Circle(
        circleId: const CircleId('office_radius'),
        center: _officeLatLng,
        radius: AppConstants.maxAttendanceRadiusMeters,
        fillColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        strokeColor: AppColors.primaryBlue,
        strokeWidth: 2,
      ),
    };
  }

  Future<void> _handleCheckIn() async {
    final attendance = context.read<AttendanceProvider>();
    final success = await attendance.checkIn();
    if (!mounted) return;

    if (success) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await context.read<NotificationProvider>().addNotification(
            title: 'Absen Masuk Berhasil',
            message:
                'Presensi masuk berhasil dicatat pada $timeStr WIB di ${AppConstants.officeName}.',
            type: 'check_in',
          );
      if (mounted) ToastOverlay.show(context, 'Absen masuk berhasil!');
    } else {
      final msg = attendance.errorMessage ?? 'Gagal absen masuk.';
      ToastOverlay.show(context, msg);
    }
  }

  Future<void> _handleCheckOut() async {
    final attendance = context.read<AttendanceProvider>();
    final success = await attendance.checkOut();
    if (!mounted) return;

    if (success) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await context.read<NotificationProvider>().addNotification(
            title: 'Absen Pulang Berhasil',
            message:
                'Presensi pulang berhasil dicatat pada $timeStr WIB. Selamat beristirahat!',
            type: 'check_out',
          );
      if (mounted) ToastOverlay.show(context, 'Absen keluar berhasil!');
    } else {
      final msg = attendance.errorMessage ?? 'Gagal absen keluar.';
      ToastOverlay.show(context, msg);
    }
  }

  Future<void> _openGoogleMapsApp() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${AppConstants.officeLatitude},${AppConstants.officeLongitude}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ToastOverlay.show(context, 'Tidak dapat membuka Google Maps');
      }
    } catch (e) {
      if (mounted) ToastOverlay.show(context, 'Gagal membuka Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profileUser = context.watch<ProfileProvider>().user;
    final userName = profileUser?.name ?? user?.name ?? 'Peserta PPKD';

    final attendance = context.watch<AttendanceProvider>();
    final today = attendance.todayAttendance;
    final stats = attendance.stats;

    final hasCheckedIn = today?.checkInTime != null;
    final hasCheckedOut = today?.checkOutTime != null;
    final isWithinRadius = attendance.isWithinRadius;
    final isLocationLoading = attendance.isLocationLoading;
    final isActionLoading = attendance.isLoading;

    final distanceMeters = attendance.distanceToOffice;
    final formattedDistance = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(2)} km'
        : '${distanceMeters.toStringAsFixed(0)} m';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Wavy Header with Notification ────────────────────
              AppWavyHeader(
                subtitle: _getGreeting(),
                title: userName.toUpperCase(),
                height: 175,
                trailing: const NotificationButton(),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Google Maps Section (Radius Geofencing) ───────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.map_1,
                              color: AppColors.primaryBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Peta Lokasi Presensi',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            attendance.checkPermissionsAndGetLocation();
                            if (attendance.currentPosition != null &&
                                _mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(
                                    attendance.currentPosition!.latitude,
                                    attendance.currentPosition!.longitude,
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLocationLoading)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryBlue,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Iconsax.refresh,
                                    size: 14,
                                    color: AppColors.primaryBlue,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  'Perbarui GPS',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Map Container
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.inputBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _officeLatLng,
                              zoom: 15.0,
                            ),
                            markers: _buildMarkers(attendance),
                            circles: _buildCircles(),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            mapToolbarEnabled: true,
                            gestureRecognizers:
                                <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                            onMapCreated: (controller) {
                              _mapController = controller;
                              log('GoogleMap created for HomeScreen');
                              if (attendance.currentPosition != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: LatLng(
                                        attendance.currentPosition!.latitude,
                                        attendance.currentPosition!.longitude,
                                      ),
                                      zoom: 15.5,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          // Top-Left: Direct Navigate to Google Maps Button
                          Positioned(
                            top: 12,
                            left: 12,
                            child: InkWell(
                              onTap: _openGoogleMapsApp,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.routing,
                                      size: 16,
                                      color: AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Buka Rute',
                                      style: AppTextStyles.captionSmall.copyWith(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Top-Right: Focus Office / My Location Buttons
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'focusOffice',
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryBlue,
                                  elevation: 2,
                                  onPressed: () {
                                    _mapController?.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: _officeLatLng,
                                          zoom: 16.0,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Iconsax.buildings,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: 'focusMe',
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  onPressed: () {
                                    if (attendance.currentPosition != null) {
                                      _mapController?.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            target: LatLng(
                                              attendance
                                                  .currentPosition!.latitude,
                                              attendance
                                                  .currentPosition!.longitude,
                                            ),
                                            zoom: 16.0,
                                          ),
                                        ),
                                      );
                                    } else {
                                      attendance
                                          .checkPermissionsAndGetLocation();
                                    }
                                  },
                                  child: const Icon(Iconsax.gps, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 12),

                // ── Radius Status & Current Address Card ─────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isWithinRadius
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isWithinRadius
                                    ? 'Dalam Radius Presensi'
                                    : 'Di Luar Radius Presensi',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isWithinRadius
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isWithinRadius
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Jarak: $formattedDistance',
                              style: AppTextStyles.captionSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isWithinRadius
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Iconsax.location,
                            size: 15,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              attendance.currentAddress,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (!isWithinRadius) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Maksimal radius adalah 500 m dari kantor untuk dapat melakukan absensi.',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Attendance Hero Card (Masuk / Pulang) ─────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.building_4,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppConstants.officeName,
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hasCheckedOut
                                  ? const Color(0xFF3B82F6)
                                  : (hasCheckedIn
                                      ? const Color(0xFF22C55E)
                                      : Colors.white.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              hasCheckedOut
                                  ? 'Selesai'
                                  : (hasCheckedIn
                                      ? 'Sudah Masuk'
                                      : 'Belum Presensi'),
                              style: AppTextStyles.captionSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Presensi Hari Ini (08:00 - 16:00 WIB)',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Masuk',
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  today?.checkInTime ?? '--:--',
                                  style:
                                      AppTextStyles.headingLilitaWhite.copyWith(
                                    fontSize: 22,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pulang',
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  today?.checkOutTime ?? '--:--',
                                  style:
                                      AppTextStyles.headingLilitaWhite.copyWith(
                                    fontSize: 22,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Single Dynamic Action Button ──────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: () {
                          if (isActionLoading) {
                            return ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                disabledBackgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            );
                          }

                          if (!hasCheckedIn) {
                            // Belum Masuk -> Tombol Absen Masuk
                            final canCheckIn = isWithinRadius;
                            return ElevatedButton.icon(
                              onPressed: canCheckIn ? _handleCheckIn : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canCheckIn
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                foregroundColor: canCheckIn
                                    ? AppColors.primaryBlue
                                    : Colors.white,
                                disabledBackgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                disabledForegroundColor: Colors.white,
                                side: canCheckIn
                                    ? BorderSide.none
                                    : BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                      ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: canCheckIn ? 2 : 0,
                              ),
                              icon: Icon(
                                canCheckIn
                                    ? Iconsax.login_1
                                    : Iconsax.location_slash,
                                size: 18,
                                color: canCheckIn
                                    ? AppColors.primaryBlue
                                    : Colors.white,
                              ),
                              label: Text(
                                canCheckIn
                                    ? 'Absen Masuk'
                                    : 'Di Luar Radius ($formattedDistance)',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: canCheckIn
                                      ? AppColors.primaryBlue
                                      : Colors.white,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          } else if (!hasCheckedOut) {
                            // Sudah Masuk, Belum Pulang -> Tombol Absen Pulang
                            final canCheckOut = isWithinRadius;
                            return ElevatedButton.icon(
                              onPressed: canCheckOut ? _handleCheckOut : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canCheckOut
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                foregroundColor: canCheckOut
                                    ? const Color(0xFF0D92BD)
                                    : Colors.white,
                                disabledBackgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                disabledForegroundColor: Colors.white,
                                side: canCheckOut
                                    ? BorderSide.none
                                    : BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                      ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: canCheckOut ? 2 : 0,
                              ),
                              icon: Icon(
                                canCheckOut
                                    ? Iconsax.logout_1
                                    : Iconsax.location_slash,
                                size: 18,
                                color: canCheckOut
                                    ? const Color(0xFF0D92BD)
                                    : Colors.white,
                              ),
                              label: Text(
                                canCheckOut
                                    ? 'Absen Pulang'
                                    : 'Di Luar Radius ($formattedDistance)',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: canCheckOut
                                      ? const Color(0xFF0D92BD)
                                      : Colors.white,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          } else {
                            // Sudah Masuk & Pulang -> Presensi Selesai
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Iconsax.tick_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Presensi Hari Ini Selesai',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Monthly Attendance Statistics ────────────────────────
                Text(
                  'Statistik Presensi Bulan Ini',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      label: 'Total Hadir',
                      value: (stats?.totalMasuk ?? 0).toString(),
                      icon: Iconsax.user_tick,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Total Izin',
                      value: (stats?.totalIzin ?? 0).toString(),
                      icon: Iconsax.document_text,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Total Absensi',
                      value: (stats?.totalAbsen ?? 0).toString(),
                      icon: Iconsax.chart_2,
                      color: AppColors.primaryBlue,
                    ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTextStyles.statNumber.copyWith(
                fontSize: 22,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
