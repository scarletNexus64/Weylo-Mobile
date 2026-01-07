import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/story.dart';
import '../../providers/auth_provider.dart';
import '../../services/story_service.dart';
import '../common/avatar_widget.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  final StoryService _storyService = StoryService();
  List<UserStories> _stories = [];
  List<Story> _myStories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final results = await Future.wait([
        _storyService.getFeed(),
        _storyService.getMyStories(),
      ]);
      setState(() {
        _stories = results[0] as List<UserStories>;
        _myStories = results[1] as List<Story>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (_isLoading) {
      return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMyStory(context, user);
          }
          final userStories = _stories[index - 1];
          return _StoryItem(
            userStories: userStories,
            onTap: () => context.push('/stories/${userStories.user.id}'),
          );
        },
      ),
    );
  }

  Widget _buildMyStory(BuildContext context, user) {
    final hasStory = _myStories.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasStory) {
          context.push('/my-stories');
        } else {
          context.push('/create-story');
        }
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasStory
                      ? Border.all(
                          color: AppColors.primary,
                          width: 2,
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(2),
                child: AvatarWidget(
                  imageUrl: user?.avatar,
                  name: user?.fullName,
                  size: 60,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ma story',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final UserStories userStories;
  final VoidCallback? onTap;

  const _StoryItem({
    required this.userStories,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          StoryAvatarWidget(
            imageUrl: userStories.user.avatar,
            name: userStories.user.fullName,
            size: 60,
            hasUnviewedStory: userStories.hasUnviewed,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 68,
            child: Text(
              userStories.user.firstName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: userStories.hasUnviewed ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
