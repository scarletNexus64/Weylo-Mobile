import 'package:get/get.dart';

import '../controllers/confessions_controller.dart';

class ConfessionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConfessionsController>(
      () => ConfessionsController(),
    );
  }
}
