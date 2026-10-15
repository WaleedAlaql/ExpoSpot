import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FloatingExpoShowcase extends StatelessWidget {
  const FloatingExpoShowcase({super.key, required this.animation});

  final Animation<double> animation;

  static const _images = [
    _ShowcaseImage(
      assetPath: 'assets/onboarding/onboarding_1.jpg',
      width: 118,
      height: 148,
      rotation: -0.08,
      alignment: Alignment(0.85, -0.55),
    ),
    _ShowcaseImage(
      assetPath: 'assets/onboarding/onboarding_2.jpg',
      width: 132,
      height: 162,
      rotation: 0.06,
      alignment: Alignment(-0.75, -0.35),
    ),
    _ShowcaseImage(
      assetPath: 'assets/onboarding/onboarding_3.jpg',
      width: 126,
      height: 154,
      rotation: -0.04,
      alignment: Alignment(0.05, -0.72),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < _images.length; i++)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final drift = (animation.value - 0.5) * (i.isEven ? 8 : -6);
                return Transform.translate(
                  offset: Offset(0, drift),
                  child: child,
                );
              },
              child: Align(
                alignment: _images[i].alignment,
                child: Transform.rotate(
                  angle: _images[i].rotation,
                  child: _OrganicPhotoFrame(image: _images[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShowcaseImage {
  const _ShowcaseImage({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.rotation,
    required this.alignment,
  });

  final String assetPath;
  final double width;
  final double height;
  final double rotation;
  final Alignment alignment;
}

class _OrganicPhotoFrame extends StatelessWidget {
  const _OrganicPhotoFrame({required this.image});

  final _ShowcaseImage image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: image.width,
      height: image.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(42),
          topRight: const Radius.circular(28),
          bottomLeft: const Radius.circular(26),
          bottomRight: const Radius.circular(48),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.keppelGreen.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        image.assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: AppColors.keppelGreen.withValues(alpha: 0.25),
          child: const Icon(Icons.image_outlined, color: Colors.white70, size: 36),
        ),
      ),
    );
  }
}
