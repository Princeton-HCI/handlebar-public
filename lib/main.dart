import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:handlebar/extensions/context_extensions.dart';
import 'package:handlebar/navigation/navigation_router.dart';
import 'package:handlebar/network/request_handler.dart';
import 'package:handlebar/design-system/layout_theme.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  // Initialize RequestHandler to load stored authentication state
  final requestHandler = RequestHandler();
  await requestHandler.initialize();

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

          final handlebarTheme =
              ThemeData(useMaterial3: true, extensions: [layoutTheme]);

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
