import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {




  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,


      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,


      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
