import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Google sign-in chip — white surface, neutral border, official G mark.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  static const _googleBorder = Color(0xFFDADCE0);
  static const _googleText = Color(0xFF3C4043);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        side: const BorderSide(color: _googleBorder),
      ),
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/google_g.svg',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: AppTypography.button(context).copyWith(
                            color: _googleText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
