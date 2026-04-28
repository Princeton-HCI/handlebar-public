import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/storage/auth_token_store.dart';
import '../features/crepe/services/collector_service.dart';
import '../features/crepe/services/crepe_service.dart';
import 'app_locator.dart';
import 'design-system/layout_theme.dart';
import 'navigation_router.dart';

void main() async {
  usePathUrlStrategy();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://b1bf91d053c22b79e77b7dd8f41a859b@o4506775983947776.ingest.us.sentry.io/4509967306850304';
      options.environment = kDebugMode ? 'development' : 'production';
      options.sendDefaultPii = true;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      setupLocator();

      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        debugPrint(
            '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
      });

      // Load stored auth tokens (Just reads from secure storage, doesn't validate network)
      getIt<AuthTokenStore>().init();

      runApp(
        SentryWidget(
          child: const HandlebarApp(),
        ),
      );
    },
  );
}

class HandlebarApp extends StatefulWidget {
  const HandlebarApp({super.key});

  @override
  State<HandlebarApp> createState() => _HandlebarAppState();
}

class _HandlebarAppState extends State<HandlebarApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      _verifyAccessibilityStatusGlobally();
    }
  }

  Future<void> _verifyAccessibilityStatusGlobally() async {
    // Accessibility Service doesn't work in the web, bail out
    if (kIsWeb) return;

    final authStore = getIt<AuthTokenStore>();
    //  Only bother checking if they are actually logged in
    if (authStore.isAuthenticated) {
      final isEnabled =
          await getIt<CrepeService>().isAccessibilityServiceEnabled();
      authStore.setNeedsAccessibilityAcceptance(!isEnabled);

      await getIt<CollectorService>().syncMonitoringState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.width >= layoutTablet.tabletBreakpoint;
    final layoutTheme = isTablet ? layoutTablet : layoutMobile;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Handlebar',
      routerConfig: navigationRouter,
      theme: _buildTheme(layoutTheme),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
        multitouchDragStrategy: MultitouchDragStrategy.latestPointer,
      ),
    );
  }

  ThemeData _buildTheme(dynamic layoutTheme) {
    // 1. Generate the base theme using FlexColorScheme
    final baseTheme = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: Colors.black,
        primaryContainer: Colors.white,
        secondary: Colors.black87,
        appBarColor: Colors.white,
        error: Color(0xFFD32F2F),
      ),
      blendLevel: 0,
      scaffoldBackground: Colors.white,
      useMaterial3: true,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 8,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorBorderWidth: 1.0,
        inputDecoratorFocusedBorderWidth: 2.0,
        inputDecoratorFillColor: Colors.white,
        inputDecoratorBackgroundAlpha: 0,
        inputDecoratorContentPadding: EdgeInsets.all(16),
        elevatedButtonElevation: 4,
        cardElevation: 6,
      ),
      extensions: [layoutTheme],
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      textTheme: GoogleFonts.balsamiqSansTextTheme(baseTheme.textTheme),
      colorScheme: baseTheme.colorScheme.copyWith(
        surface: Colors.white,
        surfaceDim: Colors.white,
        surfaceBright: Colors.white,
        surfaceContainer: Colors.white,
        surfaceContainerHigh: Colors.white,
        surfaceContainerHighest: Colors.white,
        surfaceContainerLow: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceTint: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          position: PopupMenuPosition.under,
          menuPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(12.0),
          )),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
