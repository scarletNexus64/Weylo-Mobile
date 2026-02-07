import 'package:get/get.dart';

import '../controllers/promotions_controller.dart';

class PromotionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromotionsController>(
      () => PromotionsController(),
    );
  }
}
