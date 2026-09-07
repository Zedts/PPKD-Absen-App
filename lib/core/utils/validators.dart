/// Validation helpers used across auth forms.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _letterRegex = RegExp(r'[a-zA-Z]');
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _numberRegex = RegExp(r'[0-9]');
  static final RegExp _symbolRegex = RegExp(r'[^a-zA-Z0-9]');

  /// Returns an error string if [email] is invalid, otherwise `null`.
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Returns an error string if [password] is invalid, otherwise `null`.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password wajib diisi';
    }
    final letterCount = _letterRegex.allMatches(password).length;
    if (letterCount < 3 ||
        !_uppercaseRegex.hasMatch(password) ||
        !_numberRegex.hasMatch(password) ||
        !_symbolRegex.hasMatch(password)) {
      return 'Password minimal 3 huruf, dan mengandung huruf besar, angka serta simbol';
    }
    return null;
  }

  /// Returns an error string if [name] is invalid, otherwise `null`.
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Nama wajib diisi';
    }
    return null;
  }

  /// Returns an error if [confirm] doesn't match [password].
  static String? validateConfirmPassword(String? confirm, String password) {
    if (confirm == null || confirm.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (confirm != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  /// Returns an error if [otp] is invalid.
  static String? validateOtp(String? otp) {
    if (otp == null || otp.trim().isEmpty) {
      return 'Kode OTP wajib diisi';
    }
    if (otp.trim().length < 4) {
      return 'Kode OTP tidak valid';
    }
    return null;
  }
}
