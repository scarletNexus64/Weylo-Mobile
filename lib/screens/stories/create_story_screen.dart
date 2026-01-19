import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final StoryService _storyService = StoryService();

  File? _selectedMedia;
  bool _isVideo = false;
  bool _isUploading = false;
  Color _backgroundColor = AppColors.primary;

  final List<Color> _backgroundColors = [
    AppColors.primary,
    Colors.purple,
    Colors.pink,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.deepOrange,
    Colors.cyan,
    Colors.amber,
    const Color(0xFF1a1a2e), // Dark blue
    const Color(0xFF16213e), // Navy
    const Color(0xFF0f3460), // Deep blue
    const Color(0xFFe94560), // Coral
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _isVideo = true;
      });
    }
  }

  Future<void> _publishStory() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedMedia == null && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storyContentRequired)),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _storyService.createStory(
        media: _selectedMedia,
        text: _textController.text.trim(),
        backgroundColor: _selectedMedia == null
            ? '#${_backgroundColor.value.toRadixString(16).substring(2)}'
            : null,
        type: _selectedMedia == null
            ? 'text'
            : (_isVideo ? 'video' : 'image'),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.storyPublishedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      // Detailed error logging for debugging
      debugPrint('=== Story Upload Error ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: ${e.toString()}');
      debugPrint('Media path: ${_selectedMedia?.path}');
      debugPrint('Is video: $_isVideo');
      debugPrint('Has text: ${_textController.text.isNotEmpty}');
      debugPrint('==========================');

      // Show user-friendly error message
      String errorMessage = l10n.storyPublishError;
      if (e.toString().contains('DioException')) {
        errorMessage = l10n.connectionError;
      } else if (e.toString().contains('type')) {
        errorMessage = l10n.unsupportedFileFormat;
      } else if (e.toString().contains('size')) {
        errorMessage = l10n.fileTooLarge;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage\n${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _publishStory,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    l10n.publishAction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background/Preview
          if (_selectedMedia != null)
            _isVideo
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  )
                : Image.file(
                    _selectedMedia!,
                    fit: BoxFit.cover,
                  )
          else
            Container(
              color: _backgroundColor,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: TextField(
                    controller: _textController,
                    cursorColor: _getContrastColor(_backgroundColor),
                    style: TextStyle(
                      color: _getContrastColor(_backgroundColor),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                          color: _backgroundColor.computeLuminance() > 0.5
                              ? Colors.black38
                              : Colors.white38,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: l10n.storyWriteHint,
                      hintStyle: TextStyle(
                        color: _getContrastColor(_backgroundColor).withOpacity(0.6),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Color selector (for text stories)
                  if (_selectedMedia == null)
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _backgroundColors.length,
                        itemBuilder: (context, index) {
                          final color = _backgroundColors[index];
                          final isSelected = _backgroundColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _backgroundColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Media buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMediaButton(
                        icon: Icons.photo_library,
                        label: l10n.galleryLabel,
                        onTap: _pickImage,
                      ),
                      _buildMediaButton(
                        icon: Icons.camera_alt,
                        label: l10n.photoAction,
                        onTap: _takePhoto,
                      ),
                      _buildMediaButton(
                        icon: Icons.videocam,
                        label: l10n.videoLabel,
                        onTap: _pickVideo,
                      ),
                      if (_selectedMedia != null)
                        _buildMediaButton(
                          icon: Icons.text_fields,
                          label: l10n.textLabel,
                          onTap: () {
                            setState(() {
                              _selectedMedia = null;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Clear media button
          if (_selectedMedia != null)
            Positioned(
              top: 100,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMedia = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Retourne la couleur de contraste (blanc ou noir) selon la luminosité du fond
  Color _getContrastColor(Color backgroundColor) {
    // Calcule la luminosité relative du fond
    final luminance = backgroundColor.computeLuminance();
    // Si le fond est clair, utiliser du texte foncé, sinon du texte clair
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
