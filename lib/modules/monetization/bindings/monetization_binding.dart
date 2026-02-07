import 'package:get/get.dart';

import '../controllers/monetization_controller.dart';

class MonetizationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MonetizationController>(
      () => MonetizationController(),
    );
  }
}
