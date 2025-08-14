import 'package:handlebar/navigation/navigation_router.dart';
import 'package:handlebar/network/request_handler.dart';
import 'package:handlebar/services/collector_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:logging/logging.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  
  // Initialize RequestHandler to load stored authentication state
  final requestHandler = RequestHandler();
  await requestHandler.initialize();
  
  runApp(const HandlebarApp());
}


class HandlebarApp extends StatefulWidget {
  const HandlebarApp({super.key});

  @override
  State<HandlebarApp> createState() => _HandlebarAppState();
}

class _HandlebarAppState extends State<HandlebarApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navRouter = navigationRouter();
    return PlatformProvider(
      builder: (context) => PlatformTheme(
          builder: (context) => PlatformApp.router(
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
            ],
            title: 'Handlebar',
            routerConfig: navRouter,
            material: (_, __) => MaterialAppRouterData(),
            cupertino: (_, __) => CupertinoAppRouterData(),
          ),
      ),
        settings: PlatformSettingsData(iosUsesMaterialWidgets: true),
    );
  }
}
