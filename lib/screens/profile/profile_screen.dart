import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_wavy_header.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/notification_modal.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/toast_overlay.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  void _showEditProfileModal(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    String? nameError;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Profil',
                          style: AppTextStyles.headingSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.close_circle, size: 22),
                          color: AppColors.textLight,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nama Lengkap',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: nameController,
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Iconsax.user,
                      errorText: nameError,
                      onDebounceChanged: (val) {
                        if (nameError != null) {
                          setModalState(() => nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Simpan Perubahan',
                      isLoading: isSaving,
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          setModalState(() {
                            nameError = 'Nama tidak boleh kosong';
                          });
                          return;
                        }
                        if (newName.length < 3) {
                          setModalState(() {
                            nameError = 'Nama minimal 3 karakter';
                          });
                          return;
                        }

                        setModalState(() => isSaving = true);
                        final profileProvider =
                            context.read<ProfileProvider>();
                        final success =
                            await profileProvider.updateProfile(newName);

                        if (!context.mounted) return;
                        setModalState(() => isSaving = false);

                        if (success) {
                          Navigator.of(ctx).pop();
                          ToastOverlay.show(
                            context,
                            'Profil berhasil diperbarui',
                          );
                        } else {
                          final msg = profileProvider.errorMessage ??
                              'Gagal memperbarui profil';
                          ToastOverlay.show(context, msg);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTentangAplikasiModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // App Logo / Icon Badge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.building_3,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),

              // App Name & Subtitle from AppConstants
              Text(
                AppConstants.appName,
                style: AppTextStyles.headingLilita.copyWith(
                  fontSize: 22,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                AppConstants.appSubtitle,
                style: AppTextStyles.accentPacifico.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),

              // Version Badge from AppConstants
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Versi ${AppConstants.appVersion} (Build ${AppConstants.appBuildNumber})',
                  style: AppTextStyles.badgeText.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Description from AppConstants
              Text(
                AppConstants.appDescription,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.inputBorder, height: 1),
              const SizedBox(height: 14),

              // Details from AppConstants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pengembang',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  Text(
                    AppConstants.appDeveloper,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hak Cipta',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  Text(
                    AppConstants.appCopyright,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'TUTUP',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Keluar',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (context.mounted) {
                ToastOverlay.show(context, 'Berhasil keluar');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Keluar',
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileUser = context.watch<ProfileProvider>().user;
    final authUser = context.watch<AuthProvider>().user;
    final user = profileUser ?? authUser;

    final name = user?.name ?? 'Peserta PPKD';
    final email = user?.email ?? 'peserta@ppkd.jakarta.go.id';
    final jenisKelamin = user?.jenisKelamin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ProfileProvider>().fetchProfile();
        },
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            children: [
              // ── Top Wavy Header ──────────────────────────────────────
              const AppWavyHeader(
                subtitle: 'Akun Saya,',
                title: 'PROFIL PESERTA',
                height: 175,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  children: [
                    // ── Avatar & User Info Card ─────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.inputBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryLight,
                              AppColors.primaryBlue,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: AppTextStyles.headingLilitaWhite.copyWith(
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Peserta Pelatihan PPKD',
                              style: AppTextStyles.badgeText,
                            ),
                          ),
                          if (jenisKelamin != null && jenisKelamin.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputBorder
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                jenisKelamin.toLowerCase() == 'l' ||
                                        jenisKelamin.toLowerCase() == 'laki-laki'
                                    ? 'Laki-laki'
                                    : 'Perempuan',
                                style: AppTextStyles.captionSmall.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Menu Settings Group ─────────────────────────────────
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Column(
                      children: [
                        _ProfileMenuTile(
                          icon: Iconsax.user_edit,
                          title: 'Edit Profil',
                          subtitle: 'Ubah nama lengkap akun',
                          onTap: () => _showEditProfileModal(context, name),
                        ),
                        const Divider(color: AppColors.inputBorder, height: 1),
                        _ProfileMenuTile(
                          icon: Iconsax.lock,
                          title: 'Keamanan & Kata Sandi',
                          subtitle: 'Atur ulang kata sandi Anda',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(color: AppColors.inputBorder, height: 1),
                        Consumer<NotificationProvider>(
                          builder: (context, notif, _) {
                            final unread = notif.unreadCount;
                            return _ProfileMenuTile(
                              icon: Iconsax.notification,
                              title: 'Notifikasi',
                              subtitle: unread > 0
                                  ? '$unread pesan belum dibaca'
                                  : 'Pengingat presensi aktif',
                              trailingWidget: unread > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        notif.badgeText,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () => showNotificationModal(context),
                            );
                          },
                        ),
                        const Divider(color: AppColors.inputBorder, height: 1),
                        _ProfileMenuTile(
                          icon: Iconsax.info_circle,
                          title: 'Tentang Aplikasi',
                          subtitle:
                              'Versi ${AppConstants.appVersion} (${AppConstants.appName})',
                          onTap: () => _showTentangAplikasiModal(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Logout Button ───────────────────────────────────────
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: _ProfileMenuTile(
                      icon: Iconsax.logout,
                      title: 'Keluar dari Akun',
                      titleColor: AppColors.error,
                      iconColor: AppColors.error,
                      showChevron: false,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ),
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

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? iconColor;
  final bool showChevron;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.iconColor,
    this.showChevron = true,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primaryBlue,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textLight,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingWidget != null) ...[
            trailingWidget!,
            const SizedBox(width: 6),
          ],
          if (showChevron)
            const Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: AppColors.textLight,
            ),
        ],
      ),
    );
  }
}
