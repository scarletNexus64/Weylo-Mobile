import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../models/story.dart';
import '../../models/user.dart';
import '../../services/story_service.dart';
import '../../services/story_reply_service.dart';
import '../../widgets/stories/story_reply_input.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final User user;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  final StoryService _storyService = StoryService();
  final StoryReplyService _replyService = StoryReplyService();

  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _loadStory(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(int index) {
    final story = widget.stories[index];

    // Mark as viewed
    _storyService.markAsViewed(story.id);

    // Reset progress
    _progressController.reset();

    // Handle video stories
    if (story.type == StoryType.video && story.mediaUrl != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl!),
      )..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _progressController.duration = _videoController!.value.duration;
          _progressController.forward();
        });
    } else {
      _progressController.duration = Duration(seconds: story.duration ?? 5);
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _loadStory(_currentIndex);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _loadStory(_currentIndex);
    }
  }

  void _pauseStory() {
    if (!_isPaused) {
      _progressController.stop();
      _videoController?.pause();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeStory() {
    if (_isPaused && !_isReplying) {
      _progressController.forward();
      _videoController?.play();
      setState(() {
        _isPaused = false;
      });
    }
  }

  void _toggleReplyMode() {
    setState(() {
      _isReplying = !_isReplying;
    });
    if (_isReplying) {
      _pauseStory();
    } else {
      _resumeStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),

            // Top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 2,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          double progress = 0;
                          if (index < _currentIndex) {
                            progress = 1;
                          } else if (index == _currentIndex) {
                            progress = _progressController.value;
                          }
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),

            // User info
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.user.avatar != null
                        ? CachedNetworkImageProvider(widget.user.avatar!)
                        : null,
                    child: widget.user.avatar == null
                        ? Text(widget.user.initials)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTime(story.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Reply input
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: StoryReplyInput(
                storyId: story.id,
                isExpanded: _isReplying,
                onTap: _toggleReplyMode,
                onSend: (content, {isAnonymous = true, voiceFile, voiceEffect}) async {
                  try {
                    if (voiceFile != null) {
                      await _replyService.sendVoiceReply(
                        storyId: story.id,
                        audioFile: voiceFile,
                        voiceEffect: voiceEffect,
                        isAnonymous: isAnonymous,
                      );
                    } else {
                      await _replyService.sendTextReply(
                        storyId: story.id,
                        content: content,
                        isAnonymous: isAnonymous,
                      );
                    }
                    _toggleReplyMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Réponse envoyée')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de l\'envoi')),
                    );
                  }
                },
                onClose: _toggleReplyMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    switch (story.type) {
      case StoryType.image:
        return story.mediaUrl != null
            ? CachedNetworkImage(
                imageUrl: story.mediaUrl!,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : const SizedBox();

      case StoryType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );

      case StoryType.text:
        return Container(
          color: _parseColor(story.backgroundColor),
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              story.content ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return AppColors.primary;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    }
    return 'Il y a ${difference.inDays}j';
  }
}
