import 'package:get/get.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/connection/presentation/controllers/connection_controller.dart';
import '../../features/connection/presentation/pages/connection_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() => Get.lazyPut<HomeController>(() => HomeController())),
    ),
    GetPage(
      name: AppRoutes.connection,
      page: () => const ConnectionPage(),
      binding: BindingsBuilder(() => Get.lazyPut<ConnectionController>(() => ConnectionController())),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
  ];
}
