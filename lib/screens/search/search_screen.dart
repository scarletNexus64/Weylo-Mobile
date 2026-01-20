import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../models/confession.dart';
import '../../models/conversation.dart';
import '../../services/user_service.dart';
import '../../services/confession_service.dart';
import '../../services/chat_service.dart';
import '../../services/widgets/common/avatar_widget.dart';
import '../../services/widgets/common/premium_badge.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final ConfessionService _confessionService = ConfessionService();
  final ChatService _chatService = ChatService();
  late TabController _tabController;

  List<User> _defaultUsers = [];
  List<User> _searchResults = [];
  List<Confession> _posts = [];
  bool _isInitialLoading = true;
  bool _isUsersSearching = false;
  bool _isPostsLoading = false;
  String _searchQuery = '';
  String _lastQuery = '';
  Map<String, ConversationIndex> _conversationIndex = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUsers() async {
    setState(() {
      _isInitialLoading = true;
    });

    try {
      final usersFuture = _userService.searchUsers('', perPage: 1000);
      final conversationsFuture = _chatService.getConversations();
      final results = await Future.wait([usersFuture, conversationsFuture]);
      final users = results[0] as List<User>;
      final conversations = results[1] as List<Conversation>;
      final conversationIndex = await _chatService.getConversationsIndexByUsername(
        conversations: conversations,
      );
      if (!mounted) return;
      setState(() {
        _defaultUsers = users;
        _conversationIndex = conversationIndex;
      });
    } catch (e) {
      debugPrint('Failed to load users for search: $e');
      if (!mounted) return;
      setState(() {
        _defaultUsers = [];
        _conversationIndex = {};
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _resetSearchState();
      return;
    }

    setState(() {
      _searchQuery = trimmed;
    });

    final shouldSearchUsers = trimmed.length >= 2;
    setState(() {
      _isPostsLoading = true;
      _isUsersSearching = shouldSearchUsers;
      _lastQuery = shouldSearchUsers ? trimmed : '';
    });

    final userSearchFuture = shouldSearchUsers
        ? _userService.searchUsers(trimmed, perPage: 100)
        : Future.value(<User>[]);

    try {
      final results =
          await Future.wait([userSearchFuture, _confessionService.searchConfessions(trimmed)]);
      final posts = results[1] as List<Confession>;
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _searchResults = shouldSearchUsers ? results[0] as List<User> : [];
        _posts = posts;
      });
    } catch (e) {
      debugPrint('Search failed: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isPostsLoading = false;
        _isUsersSearching = false;
      });
    }
  }

  void _resetSearchState() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _lastQuery = '';
      _posts = [];
      _searchResults = [];
      _isPostsLoading = false;
      _isUsersSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userCount =
        _lastQuery.isEmpty ? _defaultUsers.length : _searchResults.length;
    final postCount = _searchQuery.isEmpty ? 0 : _posts.length;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[500]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            final trimmed = value.trim();
            if (trimmed.isEmpty) {
              _resetSearchState();
            } else if (trimmed.length >= 2) {
              _search(trimmed);
            } else {
              setState(() {
                _searchQuery = '';
                _lastQuery = '';
                _posts = [];
                _searchResults = [];
              });
            }
          },
          onSubmitted: _search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _resetSearchState,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.peopleTabCount(userCount)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.article, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.postsTabCount(postCount)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildUsersPanel(), _buildPostsTab()],
            ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.searchEmptyTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.searchEmptySubtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPanel() {
    final l10n = AppLocalizations.of(context)!;

    if (_isUsersSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasQuery = _lastQuery.isNotEmpty;
    final users = hasQuery ? _searchResults : _defaultUsers;

    if (users.isEmpty) {
      final message = hasQuery ? l10n.noUsersFound : l10n.noUsersAvailable;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final sections = _buildUserSections(l10n, users);
    final sectionWidgets = <Widget>[];

    for (final section in sections) {
      if (section.users.isEmpty) continue;
      sectionWidgets.add(_buildSectionHeader(section));
      for (var i = 0; i < section.users.length; i++) {
        final user = section.users[i];
        final index = _conversationIndex[user.username];
        final bool shouldReveal = (index?.hasConversation ?? false) && (index?.isIdentityRevealed ?? false);

        sectionWidgets.add(_UserSearchTile(
          user: user,
          isIdentityRevealed: shouldReveal,
          onTap: () => context.push('/u/${user.username}'),
        ));
        if (i < section.users.length - 1) {
          sectionWidgets.add(const Divider(height: 0));
        }
      }
      sectionWidgets.add(const SizedBox(height: 12));
    }

    if (sectionWidgets.isEmpty) {
      final fallback = hasQuery ? l10n.noUsersFound : l10n.noUsersAvailable;
      return Center(child: Text(fallback, style: TextStyle(color: Colors.grey[600])));
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: sectionWidgets,
    );
  }

  Widget _buildPostsTab() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState();
    }
    if (_isPostsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildPostsList();
  }

  Widget _buildPostsList() {
    final l10n = AppLocalizations.of(context)!;
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l10n.searchNoPosts, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _PostSearchTile(
          post: post,
          onTap: () => context.push('/post/${post.id}'),
        );
      },
    );
  }

  Widget _buildSectionHeader(_UserSection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: section.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${section.users.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (section.helper.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                section.helper,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  List<_UserSection> _buildUserSections(
    AppLocalizations l10n,
    List<User> users,
  ) {
    final revealed = <User>[];
    final anonymous = <User>[];
    final withoutConversation = <User>[];

    for (final user in users) {
      final username = user.username;
      final index = _conversationIndex[username];
      final hasConversation = index?.hasConversation ?? false;
      final isIdentityRevealed = index?.isIdentityRevealed ?? false;

      if (hasConversation) {
        if (isIdentityRevealed) {
          revealed.add(user);
        } else {
          anonymous.add(user);
        }
      } else {
        withoutConversation.add(user);
      }
    }

    void sortByName(List<User> list) => list.sort(
          (a, b) => _userDisplayName(a)
              .toLowerCase()
              .compareTo(_userDisplayName(b).toLowerCase()),
        );

    sortByName(revealed);
    sortByName(anonymous);
    sortByName(withoutConversation);

    return [
      _UserSection(
        title: l10n.revealedConversations,
        helper: l10n.revealedConversationsHelper,
        accentColor: Colors.green,
        users: revealed,
      ),
      _UserSection(
        title: l10n.anonymousConversations,
        helper: l10n.anonymousConversationsHelper,
        accentColor: Colors.orange,
        users: anonymous,
      ),
      _UserSection(
        title: l10n.noConversation,
        helper: l10n.noConversationHelper,
        accentColor: Colors.blue,
        users: withoutConversation,
      ),
    ];
  }

  String _userDisplayName(User user) {
    final name = user.fullName;
    if (name.isNotEmpty) return name;
    return user.username;
  }
}

class _UserSection {
  final String title;
  final String helper;
  final Color accentColor;
  final List<User> users;

  const _UserSection({
    required this.title,
    required this.helper,
    required this.accentColor,
    required this.users,
  });
}

class _UserSearchTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  final bool isIdentityRevealed;

  const _UserSearchTile({
    required this.user,
    this.onTap,
    this.isIdentityRevealed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = isIdentityRevealed ? user.fullName : l10n.userAnonymous;
    final subtitleText =
        isIdentityRevealed ? '@${user.username}' : l10n.maskedUsername;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: AvatarWidget(
          imageUrl: isIdentityRevealed ? user.avatar : '',
          name: user.fullName,
          size: 48,
        ),
        title: Row(
          children: [
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (user.isPremium && isIdentityRevealed) ...[
              const SizedBox(width: 4),
              const VerifiedBadge(size: 14),
            ],
          ],
        ),
        subtitle: Text(subtitleText),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _PostSearchTile extends StatelessWidget {
  final Confession post;
  final VoidCallback? onTap;

  const _PostSearchTile({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.article, color: Colors.white),
        ),
        title: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            const Icon(Icons.favorite, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${post.likesCount}'),
            const SizedBox(width: 12),
            const Icon(Icons.visibility, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${post.viewsCount}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
