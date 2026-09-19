import 'package:get/get.dart';

import '../../modules/home/home_controller.dart';
import '../../modules/home/home_view.dart';
import '../../modules/connection/connection_controller.dart';
import '../../modules/connection/connection_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),

    GetPage(
      name: AppRoutes.connection,
      page: () => const ConnectionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ConnectionController>(
          () => ConnectionController(),
        );
      }),
    ),
  ];
}
