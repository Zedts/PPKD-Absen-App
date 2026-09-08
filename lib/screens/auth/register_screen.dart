import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/utils/validators.dart';
import '../../widgets/auth/auth_background.dart';
import '../../widgets/common/back_button_circle.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/google_sign_in_button.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/social_divider.dart';
import '../../widgets/common/toast_overlay.dart';
import '../main_shell.dart';
import 'sign_in_screen.dart';

/// Register / Account Creation screen with gender, batch, training, and optional profile photo.
class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // New fields required by API
  String _jenisKelamin = 'L'; // 'L' or 'P'
  int _batchId = 1; // Default Batch 1
  int? _trainingId; // Dropdown from AuthProvider.trainings
  PickedPhotoResult? _pickedPhoto;
  String get _profilePhoto => _pickedPhoto?.base64DataUri ?? '';
  bool _agreedToTerms = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ToastOverlay.show(context, 'Tidak dapat membuka tautan');
      }
    }
  }

  Future<void> _handlePickPhoto() async {
    final action = await ImagePickerHelper.showSourcePicker(
      context,
      showDeleteOption: _pickedPhoto != null,
    );
    if (action == null || !mounted) return;

    if (action == ImagePickerAction.delete) {
      _handleRemovePhoto();
      return;
    }

    final source = action == ImagePickerAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final result = await ImagePickerHelper.pickImage(source);
    if (result != null && mounted) {
      setState(() {
        _pickedPhoto = result;
      });
    }
  }

  void _handleRemovePhoto() {
    setState(() {
      _pickedPhoto = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // Default to Mobile Programming (id: 16) if available, or first item
    final trainings = context.read<AuthProvider>().trainings;
    if (trainings.any((t) => t.id == 16)) {
      _trainingId = 16;
    } else if (trainings.isNotEmpty) {
      _trainingId = trainings.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateNameDebounced(String value) {
    setState(() {
      _nameError = Validators.validateName(value);
    });
  }

  void _validateEmailDebounced(String value) {
    setState(() {
      _emailError = Validators.validateEmail(value);
    });
  }

  void _validatePasswordDebounced(String value) {
    setState(() {
      _passwordError = Validators.validatePassword(value);
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordError = Validators.validateConfirmPassword(
          _confirmPasswordController.text,
          value,
        );
      }
    });
  }

  void _validateConfirmDebounced(String value) {
    setState(() {
      _confirmPasswordError = Validators.validateConfirmPassword(
        value,
        _passwordController.text,
      );
    });
  }

  bool _validateAll() {
    final nameErr = Validators.validateName(_nameController.text);
    final emailErr = Validators.validateEmail(_emailController.text);
    final passErr = Validators.validatePassword(_passwordController.text);
    final confErr = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmPasswordError = confErr;
      _termsError = _agreedToTerms
          ? null
          : 'Anda harus menyetujui Kebijakan Privasi & Ketentuan Layanan';
    });

    return nameErr == null &&
        emailErr == null &&
        passErr == null &&
        confErr == null &&
        _agreedToTerms;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_validateAll()) {
      if (!_agreedToTerms) {
        ToastOverlay.show(
          context,
          'Anda harus menyetujui Kebijakan Privasi & Ketentuan Layanan',
        );
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final selectedTrainingId = _trainingId ??
        (authProvider.trainings.any((t) => t.id == 16)
            ? 16
            : (authProvider.trainings.isNotEmpty
                ? authProvider.trainings.first.id
                : 16));

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      jenisKelamin: _jenisKelamin,
      batchId: _batchId,
      trainingId: selectedTrainingId,
      profilePhoto: _profilePhoto,
    );

    if (!mounted) return;

    if (success) {
      ToastOverlay.show(context, 'Pendaftaran berhasil!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else {
      final errorMsg =
          authProvider.errorMessage ?? 'Pendaftaran gagal. Periksa data Anda.';
      ToastOverlay.show(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;
    final trainings = auth.trainings;

    return AuthBackground(
      sheetHeightFraction: 0.82,
      floatingWidget: const BackButtonCircle(),
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create your', style: AppTextStyles.accentMedium),
          const SizedBox(height: 2),
          Text('ACCOUNT', style: AppTextStyles.displayLarge),
        ],
      ),
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo Picker (Optional)
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _handlePickPhoto,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                      border: Border.all(
                        color: _pickedPhoto != null
                            ? AppColors.primaryBlue
                            : AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _pickedPhoto != null
                        ? ClipOval(
                            child: Image.file(
                              _pickedPhoto!.file,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Iconsax.user,
                            size: 36,
                            color: AppColors.textLight,
                          ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickedPhoto != null ? _handleRemovePhoto : _handlePickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _pickedPhoto != null ? AppColors.error : AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _pickedPhoto != null ? Iconsax.trash : Iconsax.camera,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _pickedPhoto != null
                  ? 'Ketuk untuk mengganti • Ikon merah untuk hapus'
                  : 'Foto Profil (Opsional)',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: _pickedPhoto != null ? AppColors.primaryBlue : AppColors.textLight,
                fontWeight: _pickedPhoto != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Full Name Input
          CustomTextField(
            controller: _nameController,
            hintText: 'Full Name',
            prefixIcon: Iconsax.user,
            keyboardType: TextInputType.name,
            errorText: _nameError,
            onDebounceChanged: _validateNameDebounced,
          ),
          const SizedBox(height: 16),

          // Email Input
          CustomTextField(
            controller: _emailController,
            hintText: 'Phone or Email',
            prefixIcon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onDebounceChanged: _validateEmailDebounced,
          ),
          const SizedBox(height: 16),

          // Gender Selection (Jenis Kelamin: L / P)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Jenis Kelamin',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _jenisKelamin = 'L'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _jenisKelamin == 'L'
                          ? AppColors.primaryBlue.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _jenisKelamin == 'L'
                            ? AppColors.primaryBlue
                            : AppColors.inputBorder,
                        width: _jenisKelamin == 'L' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.man,
                          size: 18,
                          color: _jenisKelamin == 'L'
                              ? AppColors.primaryBlue
                              : AppColors.textLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Laki-laki',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _jenisKelamin == 'L'
                                ? AppColors.primaryBlue
                                : AppColors.textDark,
                            fontWeight: _jenisKelamin == 'L'
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _jenisKelamin = 'P'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _jenisKelamin == 'P'
                          ? AppColors.primaryBlue.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _jenisKelamin == 'P'
                            ? AppColors.primaryBlue
                            : AppColors.inputBorder,
                        width: _jenisKelamin == 'P' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.woman,
                          size: 18,
                          color: _jenisKelamin == 'P'
                              ? AppColors.primaryBlue
                              : AppColors.textLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Perempuan',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _jenisKelamin == 'P'
                                ? AppColors.primaryBlue
                                : AppColors.textDark,
                            fontWeight: _jenisKelamin == 'P'
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Batch Selection (batch_id)
          DropdownButtonFormField<int>(
            initialValue: _batchId,
            decoration: InputDecoration(
              labelText: 'Batch Pelatihan',
              labelStyle: AppTextStyles.bodyRegular,
              prefixIcon: const Icon(
                Iconsax.layer,
                size: 20,
                color: AppColors.textLight,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.inputBorder, width: 2),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.inputBorder, width: 2),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            icon: const Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: AppColors.textLight,
            ),
            items: List.generate(7, (i) => i + 1).map((b) {
              return DropdownMenuItem<int>(
                value: b,
                child: Text('Batch $b', style: AppTextStyles.bodyMedium),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _batchId = val);
            },
          ),
          const SizedBox(height: 16),

          // Training Selection (training_id)
          DropdownButtonFormField<int>(
            initialValue: trainings.any((t) => t.id == _trainingId)
                ? _trainingId
                : (trainings.isNotEmpty ? trainings.first.id : null),
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Program Kejuruan',
              labelStyle: AppTextStyles.bodyRegular,
              prefixIcon: const Icon(
                Iconsax.teacher,
                size: 20,
                color: AppColors.textLight,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.inputBorder, width: 2),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.inputBorder, width: 2),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            icon: const Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: AppColors.textLight,
            ),
            items: trainings.map((t) {
              return DropdownMenuItem<int>(
                value: t.id,
                child: Text(
                  t.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _trainingId = val);
            },
          ),
          const SizedBox(height: 16),

          // Password Input
          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Iconsax.lock,
            obscureText: _obscurePassword,
            errorText: _passwordError,
            onDebounceChanged: _validatePasswordDebounced,
            suffixWidget: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                color: AppColors.textLight,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Input
          CustomTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            prefixIcon: Iconsax.lock,
            obscureText: _obscureConfirm,
            errorText: _confirmPasswordError,
            onDebounceChanged: _validateConfirmDebounced,
            suffixWidget: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                color: AppColors.textLight,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Policy & Terms of Service Checkbox
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: _termsError != null
                  ? Border.all(color: AppColors.error, width: 1.5)
                  : null,
              color: _termsError != null
                  ? AppColors.error.withValues(alpha: 0.04)
                  : Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (val) {
                          setState(() {
                            _agreedToTerms = val ?? false;
                            _termsError = null;
                          });
                        },
                        activeColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: _termsError != null
                              ? AppColors.error
                              : _agreedToTerms
                                  ? AppColors.primaryBlue
                                  : AppColors.textLight,
                          width: 1.5,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        children: [
                          Text(
                            'Saya menyetujui ',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _launchUrl(AppConstants.privacyPolicyUrl),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                'Kebijakan Privasi',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            ' dan ',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _launchUrl(AppConstants.termsOfServiceUrl),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                'Ketentuan Layanan',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_termsError != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      _termsError!,
                      style: AppTextStyles.errorText.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sign Up Button
          PrimaryButton(
            text: 'SIGN UP',
            isLoading: isLoading,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 12),

          // Social divider
          const SocialDivider(text: 'or sign up with'),

          // Google button
          GoogleSignInButton(
            onPressed: () {
              ToastOverlay.show(context, 'Google Sign-In segera hadir');
            },
          ),
          const SizedBox(height: 14),

          // Bottom sign in link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have account? ', style: AppTextStyles.bodySmall),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const SignInScreen(),
                    ),
                  );
                },
                child: Text('Sign In', style: AppTextStyles.linkText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

