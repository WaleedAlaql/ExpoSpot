import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_theme.dart';
import 'package:expo_spot/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';

class ExpoSpotApp extends StatelessWidget {
  const ExpoSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final textDirection = locale.languageCode == 'ar'
        ? ui.TextDirection.rtl
        : ui.TextDirection.ltr;

    return MaterialApp(
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: locale,
      theme: AppTheme.light(context),
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
