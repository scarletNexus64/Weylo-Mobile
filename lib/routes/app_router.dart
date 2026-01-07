import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:story_view/story_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/story_service.dart';
import '../services/user_service.dart';
import '../models/story.dart' hide StoryView;
import '../models/user.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main/main_navigation_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/my_profile_screen.dart';
import '../screens/messages/send_message_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stories/create_story_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';

        // Allow deep links for public profiles
        if (state.matchedLocation.startsWith('/u/')) {
          return null;
        }

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Main Navigation (with bottom nav)
        GoRoute(
          path: '/',
          name: 'main',
          builder: (context, state) => const MainNavigationScreen(),
        ),

        // Legacy home route (redirects to main)
        GoRoute(
          path: '/home',
          redirect: (_, __) => '/',
        ),

        // User Profile (public + deep link support)
        GoRoute(
          path: '/u/:username',
          name: 'user-profile',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return UserProfileScreen(username: username);
          },
        ),

        // Profile by ID
        GoRoute(
          path: '/profile/:id',
          name: 'profile-by-id',
          builder: (context, state) {
            final username = state.pathParameters['id'] ?? '';
            return UserProfileScreen(username: username);
          },
        ),

        // Chat
        GoRoute(
          path: '/chat/:id',
          name: 'chat',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return ChatScreen(conversationId: id);
          },
        ),

        // Wallet
        GoRoute(
          path: '/wallet',
          name: 'wallet',
          builder: (context, state) => const WalletScreen(),
        ),

        // Send Message (with recipient)
        GoRoute(
          path: '/send-message/:username',
          name: 'send-message-to',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return SendMessageScreen(recipientUsername: username);
          },
        ),

        // Send Message (search for recipient)
        GoRoute(
          path: '/send-message',
          name: 'send-message',
          builder: (context, state) {
            return const SendMessageScreen(recipientUsername: '');
          },
        ),

        // Payment WebView
        GoRoute(
          path: '/payment',
          name: 'payment',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'] ?? '';
            if (url.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Paiement')),
                body: const Center(child: Text('URL de paiement invalide')),
              );
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text('Paiement'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(Uri.parse(Uri.decodeComponent(url))),
              ),
            );
          },
        ),

        // New Chat (search for user to chat with)
        GoRoute(
          path: '/new-chat',
          name: 'new-chat',
          builder: (context, state) {
            return const _NewChatScreen();
          },
        ),

        // Create Confession
        GoRoute(
          path: '/create-confession',
          name: 'create-confession',
          builder: (context, state) {
            return const _CreateConfessionScreen();
          },
        ),

        // Confession Detail
        GoRoute(
          path: '/confession/:id',
          name: 'confession-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return Scaffold(
              appBar: AppBar(title: const Text('Confession')),
              body: Center(child: Text('Confession ID: $id')),
            );
          },
        ),

        // Message Detail
        GoRoute(
          path: '/message/:id',
          name: 'message-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return Scaffold(
              appBar: AppBar(title: const Text('Message')),
              body: Center(child: Text('Message ID: $id')),
            );
          },
        ),

        // Privacy Settings
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (context, state) {
            return const _PrivacySettingsScreen();
          },
        ),

        // Terms of Service
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) {
            return const _LegalScreen(title: 'Conditions d\'utilisation', type: 'terms');
          },
        ),

        // Privacy Policy
        GoRoute(
          path: '/privacy-policy',
          name: 'privacy-policy',
          builder: (context, state) {
            return const _LegalScreen(title: 'Politique de confidentialité', type: 'privacy');
          },
        ),

        // Confession/Post Detail
        GoRoute(
          path: '/post/:id',
          name: 'post-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            // TODO: Implement ConfessionDetailScreen
            return Scaffold(
              appBar: AppBar(title: const Text('Publication')),
              body: Center(child: Text('Post ID: $id')),
            );
          },
        ),

        // Settings
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // Edit Profile
        GoRoute(
          path: '/edit-profile',
          name: 'edit-profile',
          builder: (context, state) => const _EditProfileScreen(),
        ),

        // Followers/Following Lists
        GoRoute(
          path: '/followers/:username',
          name: 'followers',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            // TODO: Implement FollowersListScreen
            return Scaffold(
              appBar: AppBar(title: const Text('Abonnés')),
              body: Center(child: Text('Followers of $username')),
            );
          },
        ),
        GoRoute(
          path: '/following/:username',
          name: 'following',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            // TODO: Implement FollowingListScreen
            return Scaffold(
              appBar: AppBar(title: const Text('Abonnements')),
              body: Center(child: Text('Following by $username')),
            );
          },
        ),

        // Group
        GoRoute(
          path: '/group/:id',
          name: 'group',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            // TODO: Implement GroupChatScreen
            return Scaffold(
              appBar: AppBar(title: const Text('Groupe')),
              body: Center(child: Text('Group ID: $id')),
            );
          },
        ),

        // Stories
        GoRoute(
          path: '/stories/:userId',
          name: 'stories',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return _StoryViewerScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/my-stories',
          name: 'my-stories',
          builder: (context, state) => const _MyStoriesScreen(),
        ),
        GoRoute(
          path: '/create-story',
          name: 'create-story',
          builder: (context, state) => const CreateStoryScreen(),
        ),

        // Premium
        GoRoute(
          path: '/premium',
          name: 'premium',
          builder: (context, state) => const _PremiumScreen(),
        ),

        // Notifications
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const _NotificationsScreen(),
        ),

        // Help/About
        GoRoute(
          path: '/help',
          name: 'help',
          builder: (context, state) => const _HelpScreen(),
        ),
        GoRoute(
          path: '/about',
          name: 'about',
          builder: (context, state) => const _AboutScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Page non trouvée: ${state.uri}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Private Screen Classes ====================

/// Screen for searching and starting a new chat
class _NewChatScreen extends StatefulWidget {
  const _NewChatScreen();

  @override
  State<_NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<_NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    // TODO: Implement user search API call
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle conversation'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Recherchez un utilisateur pour\ncommencer une conversation',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Screen for creating a new confession/post
class _CreateConfessionScreen extends StatefulWidget {
  const _CreateConfessionScreen();

  @override
  State<_CreateConfessionScreen> createState() => _CreateConfessionScreenState();
}

class _CreateConfessionScreenState extends State<_CreateConfessionScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isAnonymous = true;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire quelque chose')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // TODO: Implement confession creation API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication créée avec succès!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle publication'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publish,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publier'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Qu\'avez-vous à confesser?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Publication anonyme'),
              subtitle: const Text('Votre identité sera cachée'),
              value: _isAnonymous,
              onChanged: (value) => setState(() => _isAnonymous = value),
            ),
            SwitchListTile(
              title: const Text('Publication publique'),
              subtitle: const Text('Visible par tous les utilisateurs'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for privacy settings
class _PrivacySettingsScreen extends StatefulWidget {
  const _PrivacySettingsScreen();

  @override
  State<_PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<_PrivacySettingsScreen> {
  bool _showOnlineStatus = true;
  bool _allowMessages = true;
  bool _allowComments = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Afficher le statut en ligne'),
            subtitle: const Text('Les autres peuvent voir quand vous êtes en ligne'),
            value: _showOnlineStatus,
            onChanged: (value) => setState(() => _showOnlineStatus = value),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Autoriser les messages'),
            subtitle: const Text('Recevoir des messages anonymes'),
            value: _allowMessages,
            onChanged: (value) => setState(() => _allowMessages = value),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Autoriser les commentaires'),
            subtitle: const Text('Permettre les commentaires sur vos posts'),
            value: _allowComments,
            onChanged: (value) => setState(() => _allowComments = value),
          ),
          const Divider(),
          ListTile(
            title: const Text('Utilisateurs bloqués'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to blocked users list
            },
          ),
        ],
      ),
    );
  }
}

/// Screen for legal pages (Terms, Privacy Policy)
class _LegalScreen extends StatelessWidget {
  final String title;
  final String type;

  const _LegalScreen({required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dernière mise à jour: 1er Janvier 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              'En utilisant Weylo, vous acceptez les conditions suivantes...',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '1. Utilisation du service\n\nWeylo est une plateforme de messagerie anonyme. '
              'En utilisant ce service, vous vous engagez à respecter les autres utilisateurs '
              'et à ne pas publier de contenu illégal ou offensant.\n\n'
              '2. Confidentialité\n\nNous respectons votre vie privée. Vos messages anonymes '
              'ne révèlent pas votre identité sauf si vous choisissez de la révéler.\n\n'
              '3. Responsabilité\n\nVous êtes responsable du contenu que vous publiez. '
              'Weylo se réserve le droit de supprimer tout contenu inapproprié.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Help screen with FAQ
class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Questions fréquentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'Comment envoyer un message anonyme?',
            'Allez sur le profil d\'un utilisateur et tapez sur "Envoyer un message". '
            'Votre identité restera cachée à moins que vous ne choisissiez de la révéler.',
          ),
          _buildFAQItem(
            'Comment voir qui m\'a envoyé un message?',
            'Par défaut, les messages sont anonymes. Vous pouvez demander la révélation '
            'd\'identité moyennant des pièces ou un abonnement Premium.',
          ),
          _buildFAQItem(
            'Comment partager mon lien?',
            'Allez dans votre profil et tapez sur "Partager le profil". '
            'Vous pouvez partager votre lien sur les réseaux sociaux.',
          ),
          _buildFAQItem(
            'Comment contacter le support?',
            'Envoyez un email à support@weylo.app pour toute question ou problème.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Open email client
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text('Contacter le support'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

/// About screen
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Weylo',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              const Text(
                'La plateforme de messagerie anonyme\nqui connecte les gens en toute sécurité.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Text(
                '© 2026 Weylo. Tous droits réservés.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit Profile Screen
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName ?? '';
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      final updatedUser = await userService.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text.isNotEmpty ? _lastNameController.text : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      if (mounted) {
        // Update user in auth provider
        context.read<AuthProvider>().updateUser(updatedUser);

        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Parlez de vous...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium Screen
class _PremiumScreen extends StatelessWidget {
  const _PremiumScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weylo Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Premium badge
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.star, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Weylo Premium',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Débloquez toutes les fonctionnalités',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Features
            _buildFeature(Icons.visibility, 'Voir l\'identité', 'Révélez qui vous envoie des messages'),
            _buildFeature(Icons.verified, 'Badge Premium', 'Montrez votre statut Premium'),
            _buildFeature(Icons.block, 'Sans publicités', 'Profitez d\'une expérience sans pub'),
            _buildFeature(Icons.analytics, 'Statistiques avancées', 'Analysez vos interactions'),
            const SizedBox(height: 24),
            // Pricing
            Card(
              child: ListTile(
                title: const Text('Mensuel'),
                subtitle: const Text('2 500 FCFA/mois'),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                    );
                  },
                  child: const Text('S\'abonner'),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Annuel'),
                subtitle: const Text('20 000 FCFA/an (économisez 33%)'),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                  ),
                  child: const Text('S\'abonner'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

/// Notifications Screen
class _NotificationsScreen extends StatefulWidget {
  const _NotificationsScreen();

  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  final List<_Notification> _notifications = [
    _Notification(
      icon: Icons.mail,
      title: 'Nouveau message',
      body: 'Vous avez reçu un message anonyme',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    _Notification(
      icon: Icons.person_add,
      title: 'Nouvel abonné',
      body: 'Quelqu\'un vous suit maintenant',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    _Notification(
      icon: Icons.favorite,
      title: 'Like sur votre confession',
      body: 'Votre confession a reçu un like',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n.isRead = true;
                }
              });
            },
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune notification'),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? Colors.grey.withOpacity(0.1)
                          : const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notif.icon,
                      color: notif.isRead ? Colors.grey : const Color(0xFF6366F1),
                    ),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notif.body),
                  trailing: Text(
                    _formatTime(notif.time),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    setState(() => notif.isRead = true);
                  },
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

class _Notification {
  final IconData icon;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  _Notification({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}

/// Story Viewer Screen - View stories of a user
class _StoryViewerScreen extends StatefulWidget {
  final String userId;

  const _StoryViewerScreen({required this.userId});

  @override
  State<_StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<_StoryViewerScreen> {
  final StoryController _storyController = StoryController();
  final StoryService _storyService = StoryService();
  List<StoryItem> _storyItems = [];
  List<Story> _stories = [];
  bool _isLoading = true;
  String? _error;
  User? _storyUser;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    try {
      // Load stories for this user
      final stories = await _storyService.getUserStories(widget.userId);

      if (stories.isEmpty) {
        setState(() {
          _error = 'Aucune story disponible';
          _isLoading = false;
        });
        return;
      }

      _stories = stories;
      _storyUser = stories.first.user;

      // If user is not included in story, load it separately
      if (_storyUser == null && stories.first.userId > 0) {
        try {
          final userService = UserService();
          _storyUser = await userService.getUserById(stories.first.userId);
        } catch (e) {
          // User could not be loaded, but continue with stories
          print('Could not load user: $e');
        }
      }

      if (_storyUser == null) {
        setState(() {
          _error = 'Utilisateur non trouvé';
          _isLoading = false;
        });
        return;
      }

      // Convert to StoryItems
      final items = <StoryItem>[];
      for (final story in stories) {
        if (story.isText) {
          items.add(
            StoryItem.text(
              title: story.content ?? '',
              backgroundColor: _parseColor(story.backgroundColor) ?? const Color(0xFF6366F1),
              duration: Duration(seconds: story.duration),
            ),
          );
        } else if (story.isImage && story.mediaUrl != null) {
          items.add(
            StoryItem.pageImage(
              url: story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        } else if (story.isVideo && story.mediaUrl != null) {
          items.add(
            StoryItem.pageVideo(
              story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        }

        // Mark as viewed
        _storyService.markAsViewed(story.id);
      }

      setState(() {
        _storyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null || _storyItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            _error ?? 'Aucune story disponible',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: _storyItems,
            controller: _storyController,
            onComplete: () => Navigator.of(context).pop(),
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.of(context).pop();
              }
            },
            progressPosition: ProgressPosition.top,
            repeat: false,
          ),
          // User info overlay
          if (_storyUser != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    backgroundImage: _storyUser!.avatar != null
                        ? CachedNetworkImageProvider(_storyUser!.avatar!)
                        : null,
                    child: _storyUser!.avatar == null
                        ? Text(
                            _storyUser!.initials,
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _storyUser!.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${_storyUser!.username}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// My Stories Screen - View and manage my own stories
class _MyStoriesScreen extends StatefulWidget {
  const _MyStoriesScreen();

  @override
  State<_MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<_MyStoriesScreen> {
  final StoryController _storyController = StoryController();
  final StoryService _storyService = StoryService();
  List<StoryItem> _storyItems = [];
  List<Story> _stories = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMyStories();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _loadMyStories() async {
    try {
      final stories = await _storyService.getMyStories();

      if (stories.isEmpty) {
        setState(() {
          _error = 'Vous n\'avez pas de story active';
          _isLoading = false;
        });
        return;
      }

      _stories = stories;

      // Convert to StoryItems
      final items = <StoryItem>[];
      for (final story in stories) {
        if (story.isText) {
          items.add(
            StoryItem.text(
              title: story.content ?? '',
              backgroundColor: _parseColor(story.backgroundColor) ?? const Color(0xFF6366F1),
              duration: Duration(seconds: story.duration),
            ),
          );
        } else if (story.isImage && story.mediaUrl != null) {
          items.add(
            StoryItem.pageImage(
              url: story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        } else if (story.isVideo && story.mediaUrl != null) {
          items.add(
            StoryItem.pageVideo(
              story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        }
      }

      setState(() {
        _storyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _deleteCurrentStory() async {
    if (_stories.isEmpty || _currentIndex >= _stories.length) return;

    final story = _stories[_currentIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la story?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storyService.deleteStory(story.id);

        if (_stories.length == 1) {
          Navigator.of(context).pop();
        } else {
          _loadMyStories();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story supprimée')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null || _storyItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/create-story');
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Aucune story',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/create-story');
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer une story'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: _storyItems,
            controller: _storyController,
            onComplete: () => Navigator.of(context).pop(),
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.of(context).pop();
              }
            },
            onStoryShow: (storyItem, index) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _currentIndex = index);
                }
              });
            },
            progressPosition: ProgressPosition.top,
            repeat: false,
          ),
          // User info overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  backgroundImage: user?.avatar != null
                      ? CachedNetworkImageProvider(user!.avatar!)
                      : null,
                  child: user?.avatar == null
                      ? Text(
                          user?.initials ?? '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ma story',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_stories.isNotEmpty && _currentIndex < _stories.length)
                        Text(
                          '${_stories[_currentIndex].viewsCount} vues',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom actions
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // View viewers
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  onPressed: () => _showViewers(),
                ),
                const SizedBox(width: 24),
                // Add new story
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/create-story');
                  },
                ),
                const SizedBox(width: 24),
                // Delete story
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteCurrentStory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showViewers() {
    if (_stories.isEmpty || _currentIndex >= _stories.length) return;

    final story = _stories[_currentIndex];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility),
                const SizedBox(width: 8),
                Text(
                  '${story.viewsCount} vues',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (story.viewers != null && story.viewers!.isNotEmpty)
              ...story.viewers!.map((viewer) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: viewer.user?.avatar != null
                      ? CachedNetworkImageProvider(viewer.user!.avatar!)
                      : null,
                  child: viewer.user?.avatar == null
                      ? Text(viewer.user?.initials ?? '?')
                      : null,
                ),
                title: Text(viewer.user?.fullName ?? 'Utilisateur'),
                subtitle: Text('@${viewer.user?.username ?? ''}'),
              ))
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Les vues seront affichées ici'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
