import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showJoinGroupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const JoinGroupSheet(),
  );
}

class JoinGroupSheet extends StatefulWidget {
  const JoinGroupSheet({super.key});

  @override
  State<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<JoinGroupSheet> {
  final _codeController = TextEditingController(text: 'EXPO-7K2M');

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _completeJoin() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('join_success'.tr()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.keppelGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bottleGreen.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomSafe),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
                  child: Text(
                    'join_group_modal_title'.tr(),
                    style: AppTypography.display(context).copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.bottleGreen,
                                AppColors.bottleGreen.withValues(alpha: 0.92),
                                const Color(0xFF031510),
                              ],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: const _ScanViewportPainter(),
                        ),
                        Center(
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 56,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                  child: Text(
                    'join_scan_hint'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitle(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: AppTypography.englishMetric(context).copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'join_code_hint'.tr(),
                    hintStyle: AppTypography.body(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.button),
                  child: InkWell(
                    onTap: _completeJoin,
                    borderRadius: BorderRadius.circular(AppRadii.button),
                    child: SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          'join_confirm'.tr(),
                          style: AppTypography.button(context).copyWith(
                            color: AppColors.bottleGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanViewportPainter extends CustomPainter {
  const _ScanViewportPainter();

  static const _cornerRadius = 18.0;
  static const _cornerLength = 26.0;
  static const _cornerStroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.shortestSide * 0.62).clamp(168.0, 248.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );
    final window = RRect.fromRectAndRadius(rect, const Radius.circular(_cornerRadius));

    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()..addRRect(window);
    final scrim = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(
      scrim,
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );

    final glow = Paint()
      ..color = AppColors.keppelGreen.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(window.inflate(6), glow);

    _drawCornerBrackets(canvas, rect);

    canvas.drawRRect(
      window,
      Paint()
        ..color = AppColors.keppelGreen.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.keppelGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    const r = _cornerRadius;
    const len = _cornerLength;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + r + len)
        ..lineTo(rect.left, rect.top + r)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top)
        ..lineTo(rect.left + r + len, rect.top),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - r - len, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r)
        ..lineTo(rect.right, rect.top + r + len),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.bottom - r - len)
        ..lineTo(rect.right, rect.bottom - r)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right - r, rect.bottom)
        ..lineTo(rect.right - r - len, rect.bottom),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + r + len, rect.bottom)
        ..lineTo(rect.left + r, rect.bottom)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - r)
        ..lineTo(rect.left, rect.bottom - r - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
