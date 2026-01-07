import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/confessions/confession_card.dart';
import '../../widgets/common/loading_overlay.dart';
import '../messages/send_message_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile(widget.username);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.profileUser;
        final isLoading = profileProvider.isLoading;
        final currentUser = context.read<AuthProvider>().user;
        final isOwnProfile = currentUser?.username == widget.username;

        return Scaffold(
          body: isLoading && user == null
              ? const Center(child: CircularProgressIndicator())
              : user == null
                  ? _buildErrorState(profileProvider)
                  : _buildProfileContent(user, profileProvider, isOwnProfile),
        );
      },
    );
  }

  Widget _buildErrorState(ProfileProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(provider.error ?? 'Utilisateur introuvable'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadProfile(widget.username),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    User user,
    ProfileProvider provider,
    bool isOwnProfile,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(user, provider, isOwnProfile),
            ),
            actions: [
              if (!isOwnProfile)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') {
                      _blockUser();
                    } else if (value == 'report') {
                      _reportUser();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Bloquer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Signaler'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Publications'),
                  Tab(text: 'Cadeaux'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfessionsTab(provider),
          _buildGiftsTab(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    User user,
    ProfileProvider provider,
    bool isOwnProfile,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.4),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: user.avatar != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.avatar!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                if (user.isPremium)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  user.bio!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(
                  '${user.followersCount}',
                  'Abonnés',
                  () => _showFollowersList(),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildStatItem(
                  '${user.followingCount}',
                  'Abonnements',
                  () => _showFollowingList(),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildStatItem(
                  '${user.confessionsCount ?? 0}',
                  'Publications',
                  null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            if (!isOwnProfile) _buildActionButtons(user, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(User user, ProfileProvider provider) {
    final isFollowing = user.isFollowing ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Follow/Unfollow button
        ElevatedButton(
          onPressed: provider.isFollowLoading
              ? null
              : () {
                  if (isFollowing) {
                    provider.unfollowUser(user.username);
                  } else {
                    provider.followUser(user.username);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.white : AppColors.primary,
            foregroundColor: isFollowing ? AppColors.primary : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isFollowing
                  ? const BorderSide(color: AppColors.primary)
                  : BorderSide.none,
            ),
          ),
          child: provider.isFollowLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isFollowing ? 'Abonné' : 'Suivre'),
        ),
        const SizedBox(width: 12),
        // Message button
        OutlinedButton(
          onPressed: () => _sendMessage(user),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.mail_outline, size: 18),
              SizedBox(width: 4),
              Text('Message'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfessionsTab(ProfileProvider provider) {
    final confessions = provider.userConfessions;

    if (confessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune publication',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: confessions.length,
      itemBuilder: (context, index) {
        final confession = confessions[index];
        return ConfessionCard(
          confession: confession,
        );
      },
    );
  }

  Widget _buildGiftsTab() {
    // TODO: Implement gifts received display
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun cadeau reçu',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showFollowersList() {
    // Navigate to followers list
  }

  void _showFollowingList() {
    // Navigate to following list
  }

  void _sendMessage(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendMessageScreen(recipientUsername: user.username),
      ),
    );
  }

  void _blockUser() {
    // Block user
  }

  void _reportUser() {
    // Report user
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
