import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpoTextField extends StatefulWidget {
  const ExpoTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.prefixIcon,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool obscureText;
  final bool enablePasswordToggle;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<ExpoTextField> createState() => _ExpoTextFieldState();
}

class _ExpoTextFieldState extends State<ExpoTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ExpoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.obscureText) {
      _obscured = false;
    }
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused && !_focused) {
      HapticFeedback.lightImpact();
    }
    setState(() => _focused = focused);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hideText = widget.obscureText && _obscured;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.fastOutSlowIn,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.keppelGreen.withValues(alpha: 0.28),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: hideText,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        style: AppTypography.body(context),
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelText: widget.label,
          labelStyle: AppTypography.label(context),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: _focused ? AppColors.keppelGreen : AppColors.textMuted,
          ),
          suffixIcon: widget.enablePasswordToggle
              ? IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _obscured = !_obscured);
                  },
                  icon: Icon(
                    _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            borderSide: const BorderSide(color: AppColors.border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            borderSide: const BorderSide(color: AppColors.keppelGreen, width: 1.6),
          ),
        ),
      ),
    );
  }
}
