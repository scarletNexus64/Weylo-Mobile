import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../controllers/locale_controller.dart';
import '../modules/auth/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize global controllers
    Get.put(ThemeController(), permanent: true);
    Get.put(LocaleController(), permanent: true);
    Get.put(AuthController(), permanent: true);
  }
}
