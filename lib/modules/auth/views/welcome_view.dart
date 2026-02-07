import 'package:flutter/material.dart';

import 'package:get/get.dart';

class WelcomeView extends GetView {
  const WelcomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WelcomeView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'WelcomeView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
