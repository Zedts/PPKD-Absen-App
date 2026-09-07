import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

import '../constants/api_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Holds both the local file (for fast UI preview) and the Base64 Data URI string (for backend API).
class PickedPhotoResult {
  final File file;
  final String base64DataUri;

  const PickedPhotoResult({
    required this.file,
    required this.base64DataUri,
  });
}

/// Actions available when choosing or editing a profile photo.
enum ImagePickerAction {
  camera,
  gallery,
  delete,
}

/// Helper utility for selecting, compressing, and encoding images from Camera or Gallery.
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Prompts the user with a modal bottom sheet to select Camera or Gallery (or Delete if enabled).
  /// Uses a [Material] root widget so [ListTile] ripple/ink effects render correctly without assertion errors.
  static Future<ImagePickerAction?> showSourcePicker(
    BuildContext context, {
    bool showDeleteOption = false,
  }) {
    return showModalBottomSheet<ImagePickerAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
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
                      'Pilih Foto Profil',
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
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.camera,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto (Kamera)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    'Gunakan kamera untuk mengambil foto baru',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () => Navigator.of(ctx).pop(ImagePickerAction.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.gallery,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Pilih dari Galeri',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih foto dari penyimpanan perangkat',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () => Navigator.of(ctx).pop(ImagePickerAction.gallery),
                ),
                if (showDeleteOption) ...[
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.inputBorder, height: 1),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.trash,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Hapus Foto Profil',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Gunakan avatar inisial nama secara default',
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onTap: () => Navigator.of(ctx).pop(ImagePickerAction.delete),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  /// Picks an image from [source], applies compression (1024x1024, quality 80),
  /// and returns a [PickedPhotoResult] with [File] and base64 Data URI.
  static Future<PickedPhotoResult?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      final mimeType = pickedFile.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final base64String = base64Encode(bytes);
      final dataUri = 'data:$mimeType;base64,$base64String';

      return PickedPhotoResult(
        file: File(pickedFile.path),
        base64DataUri: dataUri,
      );
    } catch (_) {
      return null;
    }
  }

  /// Convenience method that shows the source picker modal and then picks the image.
  static Future<PickedPhotoResult?> pickImageWithSourceSheet(
    BuildContext context, {
    bool showDeleteOption = false,
  }) async {
    final action = await showSourcePicker(
      context,
      showDeleteOption: showDeleteOption,
    );
    if (action == null || action == ImagePickerAction.delete) return null;
    final source = action == ImagePickerAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    return await pickImage(source);
  }

  /// Normalizes photo URLs from the backend.
  /// Handles localhost/127.0.0.1 IPs, relative paths, and HTTP scheme upgrade.
  static String normalizePhotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final trimmed = rawUrl.trim();

    // Already a Base64 data URI
    if (trimmed.startsWith('data:image')) return trimmed;

    // Check for local IP/hostnames emitted by local Laravel development
    if (trimmed.contains('127.0.0.1') || trimmed.contains('localhost')) {
      try {
        final uri = Uri.parse(trimmed);
        final baseUri = Uri.parse(ApiConstants.baseUrl);
        return uri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        ).toString();
      } catch (_) {
        return trimmed;
      }
    }

    // Relative paths like "/public/profile_photo/..." or "storage/..."
    if (trimmed.startsWith('/')) {
      return '${ApiConstants.baseUrl}$trimmed';
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return '${ApiConstants.baseUrl}/$trimmed';
    }

    // Upgrade production domain from http to https to avoid Android cleartext block
    if (trimmed.startsWith('http://appabsensi.mobileprojp.com')) {
      return trimmed.replaceFirst('http://', 'https://');
    }

    return trimmed;
  }

  /// Universally builds an avatar image supporting:
  /// - Base64 data URI (`data:image/...;base64,...`)
  /// - Network image (`http://` or `https://`) with automatic URL normalization
  /// - Local file path
  /// - Fallback widget when empty, null, or load fails
  static Widget buildAvatarImage({
    required String? photoUrlOrBase64,
    required double width,
    required double height,
    required Widget fallback,
  }) {
    if (photoUrlOrBase64 == null || photoUrlOrBase64.trim().isEmpty) {
      return fallback;
    }

    final trimmed = photoUrlOrBase64.trim();

    // Case 1: Base64 Data URI
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64String = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    // Case 2: Local File Path
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
        }
      } catch (_) {
        // Fall through to normalization
      }
    }

    // Case 3: Network URL (normalized)
    final normalizedUrl = normalizePhotoUrl(trimmed);
    return Image.network(
      normalizedUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
