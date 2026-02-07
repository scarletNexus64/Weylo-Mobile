import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/confessions_controller.dart';

class ConfessionsView extends GetView<ConfessionsController> {
  const ConfessionsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConfessionsView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'ConfessionsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
