import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline, weight: 700),
              activeIcon: Icon(Icons.mail, weight: 700),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline, weight: 700),
              activeIcon: Icon(Icons.favorite, weight: 700),
              label: 'Confessions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, weight: 700),
              activeIcon: Icon(Icons.chat_bubble, weight: 700),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined, weight: 700),
              activeIcon: Icon(Icons.group, weight: 700),
              label: 'Groupes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, weight: 700),
              activeIcon: Icon(Icons.person, weight: 700),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
