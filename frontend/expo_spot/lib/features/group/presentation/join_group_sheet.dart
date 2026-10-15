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
    builder: (_) => const JoinGroupSheet(),
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
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bottleGreen.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SizedBox(
              height: height,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      'join_group_modal_title'.tr(),
                      style: AppTypography.display(context).copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.bottleGreen,
                                    AppColors.keppelGreen.withValues(alpha: 0.35),
                                    AppColors.bottleGreen,
                                  ],
                                ),
                              ),
                              child: CustomPaint(
                                painter: _ScanReticlePainter(),
                                child: Center(
                                  child: Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 72,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'join_scan_hint'.tr(),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.subtitle(context).copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 24),
      width: size.width * 0.72,
      height: size.width * 0.72,
    );

    final glow = Paint()
      ..color = AppColors.keppelGreen.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(8), const Radius.circular(16)),
      glow,
    );

    final stroke = Paint()
      ..color = AppColors.keppelGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
