import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/groups_controller.dart';

class GroupsView extends GetView<GroupsController> {
  const GroupsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GroupsView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'GroupsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
