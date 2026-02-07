import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/premium_controller.dart';

class PremiumView extends GetView<PremiumController> {
  const PremiumView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PremiumView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'PremiumView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
