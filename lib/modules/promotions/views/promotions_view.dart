import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/promotions_controller.dart';

class PromotionsView extends GetView<PromotionsController> {
  const PromotionsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PromotionsView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'PromotionsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
