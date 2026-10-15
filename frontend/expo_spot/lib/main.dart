import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/app.dart';
import 'package:expo_spot/features/map/application/expo_dubai_graph_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      saveLocale: true,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      child: ProviderScope(
        child: const _GraphWarmup(child: ExpoSpotApp()),
      ),
    ),
  );
}

class _GraphWarmup extends ConsumerStatefulWidget {
  const _GraphWarmup({required this.child});

  final Widget child;

  @override
  ConsumerState<_GraphWarmup> createState() => _GraphWarmupState();
}

class _GraphWarmupState extends ConsumerState<_GraphWarmup> {
  @override
  void initState() {
    super.initState();
    Future<void>(() => ref.read(expoDubaiGraphProvider.future));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
