import 'package:easy_localization/easy_localization.dart';
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

/// Smaller pin for candidate meeting points (not the selected fair point).
class MeetingPointCandidateMarker extends StatelessWidget {
  const MeetingPointCandidateMarker({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface.withValues(alpha: 0.95),
            border: Border.all(color: AppColors.keppelGreen.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            Icons.place_outlined,
            size: 14,
            color: AppColors.bottleGreen.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 84),
          child: Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(context).copyWith(
              fontSize: 8,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: AppColors.bottleGreen.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// Google Maps–style place chip: white ring, grey disc, white pin glyph.
class MeetPointMarker extends StatelessWidget {
  const MeetPointMarker({
    super.key,
    this.label,
    this.highlighted = false,
  });

  final String? label;
  final bool highlighted;

  static const _googleGreyTop = Color(0xFF9AA0A6);
  static const _googleGreyBottom = Color(0xFF3C4043);

  @override
  Widget build(BuildContext context) {
    final chipLabel = label ?? 'meet_point_pin'.tr();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: highlighted
                ? Border.all(color: AppColors.keppelGreen, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: highlighted
                    ? [AppColors.keppelGreen, AppColors.bottleGreen]
                    : const [_googleGreyTop, _googleGreyBottom],
              ),
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.badge),
            border: Border.all(
              color: highlighted ? AppColors.keppelGreen : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            chipLabel,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(context).copyWith(
              color: AppColors.bottleGreen,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
