import 'package:dsc_mobile_rework/engine/navigation/navigation_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const DriversSeatCooperativeApp());
}


class DriversSeatCooperativeApp extends StatefulWidget {
  const DriversSeatCooperativeApp({super.key});

  @override
  State<DriversSeatCooperativeApp> createState() => _DriversSeatCooperativeAppState();
}

class _DriversSeatCooperativeAppState extends State<DriversSeatCooperativeApp> {
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
            title: 'DSC Mobile Flutter Demo',
            routerConfig: navRouter,
          ),
      ),
        settings: PlatformSettingsData(iosUsesMaterialWidgets: true),
    );
  }
}
