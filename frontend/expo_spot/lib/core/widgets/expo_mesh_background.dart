import 'dart:ui';

import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ExpoMeshBackground extends StatelessWidget {
  const ExpoMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF041C17),
                Color(0xFF0A2E26),
                AppColors.background,
                AppColors.background,
              ],
              stops: [0, 0.28, 0.55, 1],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _GlowOrb(
            size: 220,
            color: AppColors.keppelGreen.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          top: 120,
          left: -60,
          child: _GlowOrb(
            size: 180,
            color: AppColors.keppelGreen.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          bottom: 120,
          right: 20,
          child: _GlowOrb(
            size: 140,
            color: AppColors.bottleGreen.withValues(alpha: 0.08),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
