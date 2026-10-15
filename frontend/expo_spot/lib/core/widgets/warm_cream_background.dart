import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class WarmCreamBackground extends StatelessWidget {
  const WarmCreamBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.warmCream,
            AppColors.background,
          ],
        ),
      ),
      child: child,
    );
  }
}
