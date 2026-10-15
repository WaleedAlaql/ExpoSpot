import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/routing/spring_slide_route.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/auth/presentation/login_screen.dart';
import 'package:expo_spot/features/splash/widgets/floating_expo_showcase.dart';
import 'package:expo_spot/features/splash/widgets/onboarding_organic_background.dart';
import 'package:expo_spot/features/splash/widgets/onboarding_white_cta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _entrance = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 120, damping: 16),
        0,
        1,
        0,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(context).push(
      SpringSlideRoute(page: const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingOrganicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _entrance,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  FloatingExpoShowcase(animation: _controller),
                  const Spacer(),
                  Text(
                    'onboarding_title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.display(context).copyWith(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'onboarding_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitle(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  OnboardingWhiteCta(
                    label: 'sign_in_cta'.tr(),
                    onPressed: _openLogin,
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
