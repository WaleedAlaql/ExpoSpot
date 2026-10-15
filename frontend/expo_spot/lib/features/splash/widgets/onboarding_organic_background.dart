import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OnboardingOrganicBackground extends StatelessWidget {
  const OnboardingOrganicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.bottleGreen),
        const CustomPaint(painter: _OrganicCurvePainter()),
        child,
      ],
    );
  }
}

class _OrganicCurvePainter extends CustomPainter {
  const _OrganicCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final mint = AppColors.keppelGreen.withValues(alpha: 0.16);
    final mintSoft = AppColors.keppelGreen.withValues(alpha: 0.08);

    _drawBlob(
      canvas,
      size,
      color: mintSoft,
      path: Path()
        ..moveTo(size.width * 0.1, size.height * 0.05)
        ..quadraticBezierTo(
          size.width * 0.55,
          size.height * 0.18,
          size.width * 0.95,
          size.height * 0.08,
        )
        ..quadraticBezierTo(
          size.width * 0.7,
          size.height * 0.35,
          size.width * 0.15,
          size.height * 0.28,
        )
        ..close(),
    );

    _drawBlob(
      canvas,
      size,
      color: mint,
      path: Path()
        ..moveTo(0, size.height * 0.42)
        ..quadraticBezierTo(
          size.width * 0.35,
          size.height * 0.52,
          size.width * 0.62,
          size.height * 0.44,
        )
        ..quadraticBezierTo(
          size.width * 0.9,
          size.height * 0.38,
          size.width,
          size.height * 0.55,
        )
        ..lineTo(size.width, size.height * 0.72)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.68,
          0,
          size.height * 0.78,
        )
        ..close(),
    );
  }

  void _drawBlob(Canvas canvas, Size size, {required Color color, required Path path}) {
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
