import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class RemoteDesktopConnectivityApp extends StatelessWidget {
  const RemoteDesktopConnectivityApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: 'RemoteDesktopConnectivity',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.home,
        getPages: AppPages.pages,
      );
}
