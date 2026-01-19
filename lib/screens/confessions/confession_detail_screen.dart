import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/confession.dart';
import '../../services/confession_service.dart';
import '../../services/widgets/common/avatar_widget.dart';
import '../../services/widgets/common/link_text.dart';

class ConfessionDetailScreen extends StatefulWidget {
  final int confessionId;

  const ConfessionDetailScreen({super.key, required this.confessionId});

  @override
  State<ConfessionDetailScreen> createState() => _ConfessionDetailScreenState();
}

class _ConfessionDetailScreenState extends State<ConfessionDetailScreen> {
  final ConfessionService _confessionService = ConfessionService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Confession? _confession;
  List<ConfessionComment> _comments = [];
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoInitError = false;
  bool _isLoading = true;
  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  File? _selectedCommentImage;
  ConfessionComment? _replyToComment;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfession();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadConfession() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final confession = await _confessionService.getConfession(widget.confessionId);

      setState(() {
        _confession = confession;
        _isLoading = false;
      });

      if (confession.hasVideo) {
        _initVideoPlayer(confession.videoUrl);
      } else {
        _videoController?.dispose();
        _videoController = null;
        _isVideoInitialized = false;
        _videoInitError = false;
      }

      _loadComments();
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
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

  void _initVideoPlayer(String? url) {
    final resolvedUrl = _resolveMediaUrl(url);
    if (resolvedUrl.isEmpty) {
      setState(() {
        _isVideoInitialized = false;
        _videoInitError = true;
      });
      return;
    }

    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl))
      ..initialize().then((_) {
        if (!mounted) return;
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

  Future<void> _loadComments() async {
    try {
      setState(() => _isLoadingComments = true);

      final comments = await _confessionService.getComments(widget.confessionId);

      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _selectedCommentImage == null) return;

    try {
      setState(() => _isSendingComment = true);

      final comment = await _confessionService.addComment(
        widget.confessionId,
        content,
        image: _selectedCommentImage,
        parentId: _replyToComment?.id,
      );

      _commentController.clear();
      setState(() {
        _selectedCommentImage = null;
        _replyToComment = null;
      });

      setState(() {
        _comments.insert(0, comment);
        _isSendingComment = false;
        if (_confession != null) {
          _confession = _confession!.copyWith(
            commentsCount: _confession!.commentsCount + 1,
          );
        }
      });

      // Scroll to top to show new comment
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() => _isSendingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_confession == null) return;

    try {
      if (_confession!.isLiked) {
        final updated = await _confessionService.unlikeConfession(widget.confessionId);
        setState(() => _confession = updated);
      } else {
        final updated = await _confessionService.likeConfession(widget.confessionId);
        setState(() => _confession = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _shareConfession() {
    if (_confession == null) return;

    final shareUrl = 'https://weylo.app/post/${_confession!.id}';
    Share.share(
      'Decouvre cette publication sur Weylo! $shareUrl',
      subject: 'Publication Weylo',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication'),
        actions: [
          // Bouton pour révéler l'identité si la publication est anonyme
          if (_confession != null &&
              !_confession!.isIdentityRevealed &&
              _confession!.isAnonymous)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: _showRevealIdentityDialog,
              tooltip: 'Découvrir l\'identité',
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareConfession,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConfession,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_confession == null) {
      return const Center(child: Text('Publication non trouvee'));
    }

    return RefreshIndicator(
      onRefresh: _loadConfession,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfessionCard(),
            const Divider(height: 1),
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfessionCard() {
    final confession = _confession!;
    final imageUrl = _resolveMediaUrl(confession.imageUrl);
    final hasImage = confession.hasImage && imageUrl.isNotEmpty;
    final hasVideo = confession.hasVideo;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (confession.isIdentityRevealed && confession.author != null) {
                    context.push('/u/${confession.author!.username}');
                  }
                },
                child: _buildAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (confession.isIdentityRevealed && confession.author != null) {
                          context.push('/u/${confession.author!.username}');
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            confession.isIdentityRevealed && confession.author != null
                                ? confession.author!.fullName
                                : 'Anonyme',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (confession.author?.isPremium == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: const Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Helpers.getTimeAgo(confession.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptions(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (confession.content.isNotEmpty)
            LinkText(
              text: confession.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
              linkStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
              showPreview: true,
              previewBackgroundColor: Colors.black.withOpacity(0.04),
              previewTextColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),

          // Image
          if (hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],

          if (hasVideo) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isVideoInitialized && _videoController != null
                  ? AspectRatio(
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
                              size: 56,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: _videoInitError
                            ? const Icon(Icons.error_outline, color: Colors.grey)
                            : const CircularProgressIndicator(),
                      ),
                    ),
            ),
          ],

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${Helpers.formatNumber(confession.viewsCount)} vues',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${Helpers.formatNumber(confession.likesCount)} j\'aime',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${Helpers.formatNumber(confession.commentsCount)} commentaires',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTwitterActionButton(
                icon: confession.isLiked ? Icons.favorite : Icons.favorite_outline,
                label: 'J\'aime',
                color: confession.isLiked ? AppColors.error : null,
                onTap: _toggleLike,
              ),
              _buildTwitterActionButton(
                icon: Icons.mode_comment_outlined,
                label: 'Commenter',
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
              _buildTwitterActionButton(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: _shareConfession,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              weight: 700,
              color: color ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_confession!.isIdentityRevealed && _confession!.author != null) {
      return AvatarWidget(
        imageUrl: _confession!.author!.avatar,
        name: _confession!.author!.fullName,
        size: 48,
      );
    }
    // Avatar anonyme avec possibilité de révéler l'identité
    return GestureDetector(
      onTap: _confession!.isAnonymous ? _showRevealIdentityDialog : null,
      child: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.person_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          if (_confession!.isAnonymous)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Commentaires (${_confession?.commentsCount ?? 0})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (_isLoadingComments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun commentaire',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Soyez le premier a commenter!',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildCommentItem(_comments[index]);
            },
          ),

        // Add some padding at the bottom
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCommentItem(ConfessionComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (comment.user != null) {
                context.push('/u/${comment.user!.username}');
              }
            },
            child: AvatarWidget(
              imageUrl: comment.user?.avatar,
              name: comment.user?.fullName ?? 'Utilisateur',
              size: 36,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (comment.user != null) {
                          context.push('/u/${comment.user!.username}');
                        }
                      },
                      child: Text(
                        comment.user?.fullName ?? 'Utilisateur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (comment.user?.isPremium == true) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: const Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      Helpers.getTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (comment.parent != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.parent?.user?.fullName ?? 'Anonyme',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment.parent?.content ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (comment.content.isNotEmpty)
                  Text(
                    comment.content,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                if (comment.mediaFullUrl != null || comment.mediaUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: comment.mediaFullUrl ?? comment.mediaUrl ?? '',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _replyToComment = comment;
                    });
                  },
                  child: Text(
                    'Répondre',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToComment != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyToComment?.user?.fullName ?? 'Anonyme',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyToComment?.content ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _replyToComment = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_selectedCommentImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedCommentImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCommentImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                tooltip: 'Ajouter une image',
                icon: const Icon(Icons.image_outlined),
                onPressed: () async {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1080,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedCommentImage = File(image.path);
                    });
                  }
                },
              ),
              IconButton(
                tooltip: 'Ajouter un GIF',
                icon: const Icon(Icons.gif_box_outlined),
                onPressed: () async {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedCommentImage = File(image.path);
                    });
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              _isSendingComment
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendComment,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option pour révéler l'identité si anonyme
            if (_confession != null &&
                !_confession!.isIdentityRevealed &&
                _confession!.isAnonymous)
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.amber),
                title: const Text('Découvrir l\'identité'),
                subtitle: const Text('450 FCFA'),
                onTap: () {
                  Navigator.pop(context);
                  _showRevealIdentityDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                _shareConfession();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                _reportConfession();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRevealIdentityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.visibility, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Découvrir l\'identité'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voulez-vous payer pour découvrir l\'identité de l\'auteur de cette publication ?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.amber),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coût',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '450 FCFA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _revealIdentity();
              },
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Découvrir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _revealIdentity() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final updatedConfession = await _confessionService.revealIdentity(widget.confessionId);

      if (mounted) {
        Navigator.pop(context); // Fermer le loading
        setState(() {
          _confession = updatedConfession;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    updatedConfession.author != null
                        ? 'Identité révélée : ${updatedConfession.author!.fullName}'
                        : 'Identité révélée !',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reportConfession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler la publication'),
        content: const Text(
          'Voulez-vous signaler cette publication pour contenu inapproprie?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _confessionService.reportConfession(widget.confessionId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publication signalee')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }
}
