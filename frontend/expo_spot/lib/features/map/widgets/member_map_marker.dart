import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/localization/meeting_point_l10n.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:flutter/material.dart';

class MemberMapMarker extends StatelessWidget {
  const MemberMapMarker({
    super.key,
    required this.member,
    required this.pulse,
  });

  final GroupMember member;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final coreColor = member.isCurrentUser
        ? GoogleMapsUserDot.googleBlue
        : switch (member.connection) {
            MemberConnection.online => AppColors.keppelGreen,
            MemberConnection.lowSignal => const Color(0xFFF5A623),
            MemberConnection.offline => AppColors.textMuted,
          };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GoogleMapsUserDot(
          pulse: pulse,
          coreColor: coreColor,
          pulsingHalo: member.isCurrentUser,
        ),
        const SizedBox(height: 4),
        _NameLabel(name: member.displayName ?? member.nameKey.tr()),
      ],
    );
  }
}

/// Google Maps–style location dot: soft halo, white ring, solid core.
class GoogleMapsUserDot extends StatelessWidget {
  const GoogleMapsUserDot({
    super.key,
    required this.pulse,
    this.coreColor = googleBlue,
    this.pulsingHalo = true,
  });

  static const Color googleBlue = Color(0xFF1A73E8);
  static const Color _googleBlueLight = Color(0xFF4285F4);

  final Animation<double> pulse;
  final Color coreColor;
  final bool pulsingHalo;

  @override
  Widget build(BuildContext context) {
    final haloScale = Tween<double>(begin: 0.92, end: 1.18).animate(pulse);
    final haloOpacity = Tween<double>(begin: 0.28, end: 0.1).animate(pulse);

    final halo = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (coreColor == googleBlue ? _googleBlueLight : coreColor)
            .withValues(alpha: pulsingHalo ? 0.35 : 0.22),
      ),
    );

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (pulsingHalo)
            FadeTransition(
              opacity: haloOpacity,
              child: ScaleTransition(scale: haloScale, child: halo),
            )
          else
            halo,
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: coreColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: coreColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameLabel extends StatelessWidget {
  const _NameLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.label(context).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Classic Google Maps red drop pin (`Icons.location_on`).
class GoogleMapsRedPin extends StatelessWidget {
  const GoogleMapsRedPin({
    super.key,
    required this.size,
    this.elevated = false,
  });

  /// Google Maps marker red.
  static const Color googleRed = Color(0xFFEA4335);

  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final pin = Icon(
      Icons.location_on,
      color: googleRed,
      size: size,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 2,
          offset: Offset(0, size * 0.04),
        ),
      ],
    );

    if (!elevated) {
      return SizedBox(width: size, height: size, child: pin);
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: size * 0.22,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: pin,
      ),
    );
  }
}

/// Smaller pin for candidate meeting points (not the selected fair point).
class MeetingPointCandidateMarker extends StatelessWidget {
  const MeetingPointCandidateMarker({super.key, required this.name});

  final String name;

  static const _pinSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final displayName = MeetingPointL10n.venueName(context, name);
    final textDirection = Directionality.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 84),
          child: Text(
            displayName,
            maxLines: 2,
            textAlign: TextAlign.center,
            textDirection: textDirection,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(context).copyWith(
              fontSize: 8,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: AppColors.bottleGreen.withValues(alpha: 0.92),
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.95),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 1),
        const GoogleMapsRedPin(size: _pinSize),
      ],
    );
  }
}

/// Selected fair meet point — larger red Google pin + label.
class MeetPointMarker extends StatelessWidget {
  const MeetPointMarker({
    super.key,
    this.labelKey,
    this.label,
    this.highlighted = false,
  });

  /// Preferred: resolves with the active [BuildContext] locale.
  final String? labelKey;
  final String? label;
  final bool highlighted;

  static const _pinSize = 48.0;
  static const _pinSizeHighlighted = 56.0;

  @override
  Widget build(BuildContext context) {
    final chipLabel = labelKey != null
        ? MeetingPointL10n.trKey(context, labelKey!)
        : (label ?? 'meet_point_pin'.tr(context: context));
    final textDirection = Directionality.of(context);
    final pinSize = highlighted ? _pinSizeHighlighted : _pinSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppRadii.badge),
            border: Border.all(
              color: highlighted ? GoogleMapsRedPin.googleRed : AppColors.border,
              width: highlighted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            chipLabel,
            maxLines: 2,
            textAlign: TextAlign.center,
            textDirection: textDirection,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(context).copyWith(
              color: AppColors.bottleGreen,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        GoogleMapsRedPin(size: pinSize, elevated: highlighted),
      ],
    );
  }
}
