import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/confession.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../confession_service.dart';
import '../common/avatar_widget.dart';
import '../common/link_text.dart';
import '../common/premium_badge.dart';
import '../promotions/promote_post_modal.dart';

class ConfessionCard extends StatefulWidget {
  final Confession confession;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onPromote;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onDeleted;

  const ConfessionCard({
    super.key,
    required this.confession,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onPromote,
    this.onAuthorTap,
    this.onDeleted,
  });

  @override
  State<ConfessionCard> createState() => _ConfessionCardState();
}

class _ConfessionCardState extends State<ConfessionCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoInitError = false;
  bool _isVideoVisible = false;
  bool _isContentExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.confession.hasVideo) {
      _initVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initVideoPlayer() {
    final resolvedUrl = _resolveMediaUrl(widget.confession.videoUrl);
    if (resolvedUrl.isEmpty) {
      setState(() {
        _isVideoInitialized = false;
        _videoInitError = true;
      });
      return;
    }
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(resolvedUrl),
    )..initialize().then((_) {
        if (!mounted) return;
        _videoController?.setLooping(true);
        if (_isVideoVisible) {
          _videoController?.play();
        } else {
          _videoController?.pause();
        }
        setState(() {
          _isVideoInitialized = true;
          _videoInitError = false;
        });
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _isVideoInitialized = false;
          _videoInitError = true;
        });
      });
  }

  String _resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final cleaned = url.replaceAll('\\', '/');
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final baseUri = Uri.parse(base);

    if (cleaned.startsWith('http')) {
      final mediaUri = Uri.parse(cleaned);
      if (mediaUri.host != baseUri.host || mediaUri.port != baseUri.port) {
        final rewritten = mediaUri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        );
        return Uri.encodeFull(rewritten.toString());
      }
      return Uri.encodeFull(cleaned);
    }
    if (cleaned.startsWith('//')) return Uri.encodeFull('https:$cleaned');

    if (cleaned.startsWith('/storage/')) {
      return Uri.encodeFull('$base$cleaned');
    }
    if (cleaned.startsWith('storage/')) {
      return Uri.encodeFull('$base/$cleaned');
    }
    return Uri.encodeFull('$base/storage/$cleaned');
  }

  Confession get confession => widget.confession;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user;
    final isOwnPost = currentUser?.id == confession.authorId;
    final imageUrl = _resolveMediaUrl(confession.imageUrl);
    final hasImage = confession.hasImage && imageUrl.isNotEmpty;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Photo toujours cliquable si l'auteur existe
                  GestureDetector(
                    onTap: confession.author != null ? widget.onAuthorTap : null,
                    child: _buildAvatar(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo toujours cliquable si l'auteur existe
                        GestureDetector(
                          onTap: confession.author != null ? widget.onAuthorTap : null,
                          child: _buildAuthorInfo(context),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              Helpers.getTimeAgo(confession.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (confession.type == ConfessionType.private) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 12,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Privée',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (confession.isAnonymous) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Anonyme',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context, isOwnPost),
                  ),
                ],
              ),
            ),
            // Content
            if (confession.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: LinkText(
                  text: confession.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                      ),
                  linkStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                  maxLines: _shouldTruncateContent() && !_isContentExpanded ? 6 : null,
                  overflow: _shouldTruncateContent() && !_isContentExpanded
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                  showPreview: true,
                  previewBackgroundColor: Colors.black.withOpacity(0.04),
                  previewTextColor: AppColors.textPrimary,
                ),
              ),
            if (_shouldTruncateContent())
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isContentExpanded = !_isContentExpanded;
                    });
                  },
                  child: Text(
                    _isContentExpanded ? 'Voir moins' : 'Voir plus',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            // Image
            if (hasImage)
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 260,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 260,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.grey),
                  ),
                ),
              ),
            // Video
            if (confession.hasVideo)
              _buildVideoSection(),
            // Recipient info if private
            if (confession.recipient != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      AvatarWidget(
                        imageUrl: confession.recipient!.avatar,
                        name: confession.recipient!.fullName,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pour ${confession.recipient!.fullName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: confession.isLiked ? Icons.favorite : Icons.favorite_outline,
                    label: Helpers.formatNumber(confession.likesCount),
                    color: confession.isLiked ? AppColors.error : null,
                    onTap: widget.onLike,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: Helpers.formatNumber(confession.commentsCount),
                    onTap: widget.onComment,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.visibility_outlined,
                    label: Helpers.formatNumber(confession.viewsCount),
                  ),
                  if (isOwnPost) ...[
                    const Spacer(),
                    _buildBoostButton(context),
                    const SizedBox(width: 8),
                  ] else
                    const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    onPressed: widget.onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Toujours afficher la photo si l'auteur existe et a une photo
    if (confession.author != null && confession.author!.avatar != null) {
      return AvatarWidget(
        imageUrl: confession.author!.avatar,
        name: confession.shouldShowAuthor ? confession.author!.fullName : 'Anonyme',
        size: 44,
      );
    }
    // Sinon afficher l'icône anonyme par défaut
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.person_off,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  bool _shouldTruncateContent() {
    final content = confession.content.trim();
    if (content.isEmpty) return false;
    final lineBreaks = '\n'.allMatches(content).length + 1;
    return content.length > 240 || lineBreaks > 6;
  }

  Widget _buildVideoSection() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        height: 220,
        color: Colors.grey[200],
        child: Center(
          child: _videoInitError
              ? const Icon(Icons.error_outline, color: Colors.grey)
              : const CircularProgressIndicator(),
        ),
      );
    }

    return VisibilityDetector(
      key: ValueKey('confession_video_${confession.id}'),
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction >= 0.6;
        if (_isVideoVisible == isVisible) return;
        _isVideoVisible = isVisible;
        if (!_isVideoInitialized || _videoController == null) return;
        if (isVisible) {
          _videoController?.play();
        } else {
          _videoController?.pause();
        }
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 52,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: AppColors.primary,
              bufferedColor: Colors.white.withOpacity(0.4),
              backgroundColor: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    if (confession.shouldShowAuthor && confession.author != null) {
      return NameWithBadge(
        name: confession.author!.fullName,
        isPremium: confession.author!.isPremium,
        isVerified: confession.author!.isVerified,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        badgeSize: 16,
      );
    }
    return Text(
      'Anonyme',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildBoostButton(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.onPromote != null) {
          widget.onPromote?.call();
        } else {
          PromotePostModal.show(
            context,
            confessionId: confession.id,
            onPromoted: () {
              try {
                context.read<FeedProvider>().refresh();
              } catch (_) {}
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Booster',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, bool isOwnPost) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option promouvoir pour ses propres publications
              if (isOwnPost)
                ListTile(
                  leading: ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: const Icon(Icons.trending_up, color: Colors.white),
                  ),
                  title: const Text('Promouvoir'),
                  subtitle: const Text('Augmentez la visibilité de ce post'),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (widget.onPromote != null) {
                      widget.onPromote?.call();
                    } else {
                      // Ouvrir directement le modal de promotion
                      PromotePostModal.show(
                        context,
                        confessionId: confession.id,
                        onPromoted: () {
                          // Rafraîchir si possible
                          try {
                            context.read<FeedProvider>().refresh();
                          } catch (_) {}
                        },
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Partager'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onShare?.call();
                },
              ),
              if (isOwnPost)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _confirmDelete(context);
                  },
                ),
              if (!isOwnPost)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Signaler'),
                  onTap: () {
                    Navigator.pop(ctx);
                    // Handle report
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette publication ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final confessionService = ConfessionService();
                await confessionService.deleteConfession(confession.id);
                widget.onDeleted?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Publication supprimée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
