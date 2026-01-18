import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../messages/messages_screen.dart';
import '../confessions/confessions_screen.dart';
import '../chat/conversations_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MessagesScreen(),
    ConfessionsScreen(),
    ConversationsScreen(),
    GroupsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Refresh user data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.mail_outline),
              activeIcon: const Icon(Icons.mail),
              label: l10n.navMessages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline),
              activeIcon: const Icon(Icons.favorite),
              label: l10n.navConfessions,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: l10n.navChat,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.group_outlined),
              activeIcon: const Icon(Icons.group),
              label: l10n.navGroups,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
