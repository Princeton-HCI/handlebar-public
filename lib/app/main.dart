import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/app/navigation_router.dart';
import 'package:handlebar/app/design-system/layout_theme.dart';

import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_locator.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  // Load stored authentication state
  await tokens.init();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://b1bf91d053c22b79e77b7dd8f41a859b@o4506775983947776.ingest.us.sentry.io/4509967306850304';
      // Set environment based on Flutter build mode
      options.environment = kDebugMode ? 'development' : 'production';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: const HandlebarApp(),
      ),
    ),
  );
}

class HandlebarApp extends StatefulWidget {
  const HandlebarApp({super.key});

  @override
  State<HandlebarApp> createState() => _HandlebarAppState();
}

class _HandlebarAppState extends State<HandlebarApp> {
  @override
  Widget build(BuildContext context) {
    final navRouter = navigationRouter();
    return PlatformProvider(
        settings: PlatformSettingsData(iosUsesMaterialWidgets: true),
        builder: (context) {
          final isTablet = context.width >= layoutTablet.tabletBreakpoint;
          final layoutTheme = isTablet ? layoutTablet : layoutMobile;

          final handlebarTheme = ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            cardTheme: const CardThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            appBarTheme: const AppBarThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                surfaceTintColor: Colors.transparent,
              ),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                selectedBackgroundColor: Colors.blue[200],
              ),
            ),
            popupMenuTheme: const PopupMenuThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            extensions: [layoutTheme],
          );

          return Theme(
            data: handlebarTheme,
            child: PlatformTheme(
              builder: (context) => PlatformApp.router(
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  DefaultMaterialLocalizations.delegate,
                  DefaultWidgetsLocalizations.delegate,
                  DefaultCupertinoLocalizations.delegate,
                ],
                title: 'Handlebar',
                routerConfig: navRouter,
                material: (_, __) =>
                    MaterialAppRouterData(theme: handlebarTheme),
                cupertino: (_, __) => CupertinoAppRouterData(),
              ),
            ),
          );
        });
  }
}
