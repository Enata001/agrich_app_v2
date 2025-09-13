import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_input_field.dart';


class AdminVideoFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? video;
  final Function(Map<String, dynamic>) onSave;

  const AdminVideoFormDialog({
    super.key,
    this.video,
    required this.onSave,
  });

  @override
  ConsumerState<AdminVideoFormDialog> createState() => _AdminVideoFormDialogState();
}

class _AdminVideoFormDialogState extends ConsumerState<AdminVideoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _thumbnailUrlController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isLoading = false;
  String? _extractedVideoId;
  String? _autoThumbnailUrl;

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      _populateFields(widget.video!);
    }
    _youtubeUrlController.addListener(_onYouTubeUrlChanged);
  }

  void _populateFields(Map<String, dynamic> video) {
    _titleController.text = video['title'] ?? '';
    _descriptionController.text = video['description'] ?? '';
    _selectedCategory = video['category'] ?? 'General';
    _youtubeUrlController.text = video['youtubeUrl'] ?? '';
    _thumbnailUrlController.text = video['thumbnailUrl'] ?? '';
    _durationController.text = video['duration'] ?? '';
  }

  void _onYouTubeUrlChanged() {
    final url = _youtubeUrlController.text;
    if (url.isNotEmpty) {
      final videoId = _extractYouTubeVideoId(url);
      if (videoId != null && videoId != _extractedVideoId) {
        setState(() {
          _extractedVideoId = videoId;
          _autoThumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        });

        // Auto-fill thumbnail if not already set
        if (_thumbnailUrlController.text.isEmpty) {
          _thumbnailUrlController.text = _autoThumbnailUrl!;
        }
      }
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    _thumbnailUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.video != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 700 ? 600 : null,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Edit Video' : 'Add New Video',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // YouTube URL
                      CustomInputField(
                        controller: _youtubeUrlController,
                        label: 'YouTube URL *',
                        hint: 'https://www.youtube.com/watch?v=...',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'YouTube URL is required';
                          }
                          if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
                            return 'Please enter a valid YouTube URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title
                      CustomInputField(
                        controller: _titleController,
                        label: 'Title *',
                        hint: 'Enter video title...',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.length > 100) {
                            return 'Title must be less than 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      CustomInputField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Enter video description...',
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 500) {
                            return 'Description must be less than 500 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category and Duration Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder(),
                              ),
                              items: AppConfig.videoCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Category is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomInputField(
                              controller: _durationController,
                              label: 'Duration',
                              hint: 'e.g., 10:30',
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final regex = RegExp(r'^(\d{1,2}:)?\d{1,2}:\d{2}$');
                                  if (!regex.hasMatch(value)) {
                                return 'Format: MM:SS';
                                }
                              }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Thumbnail URL
                      CustomInputField(
                        controller: _thumbnailUrlController,
                        label: 'Thumbnail URL',
                        hint: 'Auto-filled from YouTube or enter custom URL',
                        suffixIcon: _autoThumbnailUrl != null
                            ? IconButton(
                          onPressed: () {
                            _thumbnailUrlController.text = _autoThumbnailUrl!;
                          },
                          icon: const Icon(Icons.auto_fix_high),
                          tooltip: 'Use auto-generated thumbnail',
                        )
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Preview Section
                      if (_extractedVideoId != null || _thumbnailUrlController.text.isNotEmpty)
                        _buildPreviewSection(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(isEditing ? 'Update Video' : 'Add Video'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final thumbnailUrl = _thumbnailUrlController.text.isNotEmpty
        ? _thumbnailUrlController.text
        : _autoThumbnailUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // Thumbnail preview
          if (thumbnailUrl != null)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Video info preview
          Text(
            _titleController.text.isNotEmpty ? _titleController.text : 'Video Title',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : 'Video description will appear here...',
            style: TextStyle(
              color: _descriptionController.text.isNotEmpty ? Colors.black87 : Colors.grey[500],
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedCategory,
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_durationController.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  _durationController.text,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final videoData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'youtubeUrl': _youtubeUrlController.text.trim(),
        'youtubeVideoId': _extractedVideoId,
        'embedUrl': _extractedVideoId != null
            ? 'https://www.youtube.com/embed/$_extractedVideoId'
            : null,
        'thumbnailUrl': _thumbnailUrlController.text.trim(),
        'duration': _durationController.text.trim().isEmpty
            ? '0:00'
            : _durationController.text.trim(),
        'isYouTubeVideo': true,
        'authorName': 'Admin',
        'authorId': 'admin',
      };

      await widget.onSave(videoData);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}