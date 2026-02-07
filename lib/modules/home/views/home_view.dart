import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/theme_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weylo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Obx(() => Icon(
              themeController.isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode,
            )),
            onPressed: () => themeController.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User info
            Obx(() {
              final user = authController.user;
              if (user != null) {
                return Column(
                  children: [
                    Text(
                      'Bienvenue, ${user.firstName}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }
              return const Text('Non connecté');
            }),

            const SizedBox(height: 32),

            // Navigation buttons
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/feed'),
              icon: const Icon(Icons.feed),
              label: const Text('Feed'),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/profile'),
              icon: const Icon(Icons.person),
              label: const Text('Profil'),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/messages'),
              icon: const Icon(Icons.message),
              label: const Text('Messages'),
            ),

            const SizedBox(height: 32),

            // Logout button
            Obx(() {
              if (authController.isAuthenticated) {
                return ElevatedButton.icon(
                  onPressed: () => authController.logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return ElevatedButton.icon(
                onPressed: () => Get.toNamed('/auth'),
                icon: const Icon(Icons.login),
                label: const Text('Se connecter'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

