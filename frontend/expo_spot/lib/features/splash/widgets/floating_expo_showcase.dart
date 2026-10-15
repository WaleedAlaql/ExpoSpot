import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.assetPath,
    required this.titleKey,
    required this.subtitleKey,
  });

  final String assetPath;
  final String titleKey;
  final String subtitleKey;
}

class FloatingExpoShowcase extends StatefulWidget {
  const FloatingExpoShowcase({super.key, required this.animation});

  final Animation<double> animation;

  /// Slide 1 → Riyadh copy, 2 → Japan, 3 → Dubai (assets fixed; carousel LTR in RTL app).
  static const _slides = [
    _OnboardingSlide(
      assetPath: 'assets/onboarding/onboarding_3.jpg',
      titleKey: 'onboarding_riyadh_title',
      subtitleKey: 'onboarding_riyadh_sub',
    ),
    _OnboardingSlide(
      assetPath: 'assets/onboarding/onboarding_1.jpg',
      titleKey: 'onboarding_japan_title',
      subtitleKey: 'onboarding_japan_sub',
    ),
    _OnboardingSlide(
      assetPath: 'assets/onboarding/onboarding_2.jpg',
      titleKey: 'onboarding_dubai_title',
      subtitleKey: 'onboarding_dubai_sub',
    ),
  ];

  @override
  State<FloatingExpoShowcase> createState() => _FloatingExpoShowcaseState();
}

class _FloatingExpoShowcaseState extends State<FloatingExpoShowcase> {
  static const _autoPlayInterval = Duration(seconds: 5);
  static const _pageAnimation = Duration(milliseconds: 900);

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _activeIndex = 0;
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _scheduleAutoPlay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final slide in FloatingExpoShowcase._slides) {
      precacheImage(AssetImage(slide.assetPath), context);
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) => _advanceAuto());
  }

  void _pauseAutoPlayBriefly() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer(_autoPlayInterval, _scheduleAutoPlay);
  }

  Future<void> _advanceAuto() async {
    if (!mounted || _userDragging || !_pageController.hasClients) return;
    final count = FloatingExpoShowcase._slides.length;
    final next = (_activeIndex + 1) % count;
    await _animateToPage(next);
  }

  Future<void> _animateToPage(int index) async {
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      index,
      duration: _pageAnimation,
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_activeIndex == index) return;
    setState(() => _activeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final carouselHeight = (screenWidth * 0.92).clamp(260.0, 340.0);
    final slide = FloatingExpoShowcase._slides[_activeIndex];

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final entrance = Curves.easeOutCubic.transform(widget.animation.value);
        return Transform.translate(
          offset: Offset(0, (1 - entrance) * 18),
          child: Opacity(opacity: entrance.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
            height: carouselHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _userDragging = true;
                  _autoPlayTimer?.cancel();
                } else if (notification is ScrollEndNotification) {
                  _userDragging = false;
                  _pauseAutoPlayBriefly();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: FloatingExpoShowcase._slides.length,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1;
                      double opacity = 1;
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions) {
                        final page = _pageController.page ?? index.toDouble();
                        final delta = (page - index).abs().clamp(0.0, 1.0);
                        scale = 1 - (delta * 0.06);
                        opacity = 1 - (delta * 0.22);
                      }
                      return Opacity(
                        opacity: opacity.clamp(0.78, 1.0),
                        child: Transform.scale(
                          scale: scale.clamp(0.94, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _OrganicPhotoFrame(
                        assetPath:
                            FloatingExpoShowcase._slides[index].assetPath,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ),
          const SizedBox(height: 14),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < FloatingExpoShowcase._slides.length; i++)
                  GestureDetector(
                    onTap: () {
                      _pauseAutoPlayBriefly();
                      _animateToPage(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _activeIndex == i ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _activeIndex == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 118,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previous,
                    if (current != null) current,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Column(
                key: ValueKey<int>(_activeIndex),
                children: [
                  Text(
                    slide.titleKey.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.display(context).copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slide.subtitleKey.tr(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitle(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.55,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganicPhotoFrame extends StatelessWidget {
  const _OrganicPhotoFrame({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(48),
            topRight: const Radius.circular(32),
            bottomLeft: const Radius.circular(30),
            bottomRight: const Radius.circular(52),
          ),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.38), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.keppelGreen.withValues(alpha: 0.32),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(46),
            topRight: const Radius.circular(30),
            bottomLeft: const Radius.circular(28),
            bottomRight: const Radius.circular(50),
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: AppColors.keppelGreen.withValues(alpha: 0.25),
              child: const Icon(
                Icons.image_outlined,
                color: Colors.white70,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
