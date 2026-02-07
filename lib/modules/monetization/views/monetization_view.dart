import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/monetization_controller.dart';

class MonetizationView extends GetView<MonetizationController> {
  const MonetizationView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MonetizationView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'MonetizationView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
