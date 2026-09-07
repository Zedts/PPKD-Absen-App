import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A reusable text field matching the auth_screen.html design:
/// bottom-border only, left icon, optional right icon, error state.
///
/// Includes a debounce mechanism that calls [onDebounceChanged] after
/// the user stops typing for [debounceDuration].
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final Duration debounceDuration;
  final ValueChanged<String>? onDebounceChanged;
  final String? autocompleteHints;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.errorText,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.onDebounceChanged,
    this.autocompleteHints,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  Timer? _debounce;
  bool _hasFocus = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onDebounceChanged?.call(value);
    });
  }

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          onFocusChange: (focus) => setState(() => _hasFocus = focus),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: AppTextStyles.bodyMedium,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodyRegular,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _hasFocus
                          ? AppColors.primaryBlue
                          : AppColors.textLight,
                    )
                  : null,
              suffixIcon: widget.suffixWidget,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? AppColors.error : AppColors.inputBorder,
                  width: 2,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? AppColors.error : AppColors.inputBorder,
                  width: 2,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? AppColors.error : AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 4),
            child: Text(widget.errorText!, style: AppTextStyles.errorText),
          ),
      ],
    );
  }
}
