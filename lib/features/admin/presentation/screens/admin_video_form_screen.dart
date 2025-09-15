import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/network_service.dart';
import '../../../shared/widgets/custom_input_field.dart';
import '../../../shared/widgets/loading_indicator.dart';

class AdminVideoFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? video;
  final Function(Map<String, dynamic>) onSave;

  const AdminVideoFormScreen({
    super.key,
    this.video,
    required this.onSave,
  });

  @override
  ConsumerState<AdminVideoFormScreen> createState() => _AdminVideoFormScreenState();
}

class _AdminVideoFormScreenState extends ConsumerState<AdminVideoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _thumbnailUrlController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String _selectedCategory = 'general';
  bool _isLoading = false;
  bool _isConnected = true;
  String? _autoThumbnailUrl;

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      _populateFields(widget.video!);
    }
    _youtubeUrlController.addListener(_onYouTubeUrlChanged);
    _checkNetworkStatus();

    // Debug logging
    print('DEBUG: Initial category: $_selectedCategory');
    print('DEBUG: Available categories: ${_getAvailableCategories()}');
  }

  void _checkNetworkStatus() async {
    final networkService = ref.read(networkServiceProvider);
    final isConnected = await networkService.checkConnectivity();
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  void _populateFields(Map<String, dynamic> video) {
    _titleController.text = video['title'] ?? '';
    _descriptionController.text = video['description'] ?? '';
    _youtubeUrlController.text = video['youtubeUrl'] ?? '';
    _thumbnailUrlController.text = video['thumbnailUrl'] ?? '';
    _durationController.text = video['duration'] ?? '';

    // SAFE category handling - this prevents the crash
    final videoCategory = video['category'];
    _selectedCategory = _getSafeCategory(videoCategory);

    print('DEBUG: Original category: $videoCategory');
    print('DEBUG: Safe category: $_selectedCategory');
  }

  // CRITICAL: This method prevents the dropdown crash
  String _getSafeCategory(dynamic category) {
    if (category == null) return 'general';

    final categoryStr = category.toString().toLowerCase().trim();
    final availableCategories = _getAvailableCategories();

    // Direct match
    if (availableCategories.contains(categoryStr)) {
      return categoryStr;
    }

    // Handle specific known problematic categories
    switch (categoryStr) {
      case 'modern techniques':
      case 'modern_techniques':
      case 'moderntech':
      case 'modern':
      case 'techniques':
        return 'tutorials';  // Map to tutorials
      case 'planting':
      case 'plantation':
      case 'plant':
        return 'planting';
      case 'watering':
      case 'irrigation':
      case 'water':
        return 'watering';
      case 'fertilization':
      case 'fertilizer':
      case 'fertilizing':
        return 'fertilization';
      case 'pest_control':
      case 'pest control':
      case 'pestcontrol':
      case 'pests':
        return 'pest_control';
      case 'harvesting':
      case 'harvest':
        return 'harvesting';
      case 'soil_management':
      case 'soil management':
      case 'soil':
        return 'soil_management';
      case 'crop_management':
      case 'crop management':
      case 'crops':
        return 'crop_management';
      case 'equipment':
      case 'tools':
      case 'machinery':
        return 'equipment';
      case 'tips':
      case 'tip':
      case 'advice':
        return 'tips';
      case 'tutorials':
      case 'tutorial':
      case 'how-to':
      case 'howto':
      case 'guide':
      case 'guides':
        return 'tutorials';
      default:
        print('WARNING: Unknown category "$categoryStr", defaulting to general');
        return 'general';
    }
  }

  List<String> _getAvailableCategories() {
    return [
      'general',
      'tutorials',
      'tips',
      'equipment',
      'harvesting',
      'planting',
      'watering',
      'fertilization',
      'pest_control',
      'soil_management',
      'crop_management',
    ];
  }

  List<DropdownMenuItem<String>> _buildCategoryItems() {
    return _getAvailableCategories().map((category) {
      return DropdownMenuItem(
        value: category,
        child: Text(
          _formatCategoryDisplayName(category),
        ),
      );
    }).toList();
  }

  String _formatCategoryDisplayName(String category) {
    switch (category) {
      case 'pest_control':
        return 'Pest Control';
      case 'soil_management':
        return 'Soil Management';
      case 'crop_management':
        return 'Crop Management';
      default:
        return category.split('_').map((word) =>
        word.substring(0, 1).toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  void _onYouTubeUrlChanged() {
    final url = _youtubeUrlController.text;
    if (url.isNotEmpty) {
      final videoId = _extractYouTubeVideoId(url);
      if (videoId != null) {
        setState(() {
          _autoThumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        });
      }
    } else {
      setState(() {
        _autoThumbnailUrl = null;
      });
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final thumbnailUrl = _thumbnailUrlController.text.isNotEmpty
          ? _thumbnailUrlController.text
          : _autoThumbnailUrl ?? '';

      final videoData = {
        'id': widget.video?['id'],
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'youtubeUrl': _youtubeUrlController.text.trim(),
        'thumbnailUrl': thumbnailUrl,
        'duration': _durationController.text.trim(),
        'category': _selectedCategory,
        'youtubeVideoId': _extractYouTubeVideoId(_youtubeUrlController.text.trim()),
      };

      await widget.onSave(videoData);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tutorials': return Colors.blue;
      case 'tips': return Colors.green;
      case 'equipment': return Colors.orange;
      case 'harvesting': return Colors.purple;
      case 'planting': return Colors.teal;
      case 'watering': return Colors.lightBlue;
      case 'fertilization': return Colors.amber;
      case 'pest_control': return Colors.red;
      case 'soil_management': return Colors.brown;
      case 'crop_management': return Colors.indigo;
      default: return Colors.grey;
    }
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
    final networkStatus = ref.watch(networkStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Video' : 'Add New Video',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Network status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: networkStatus.when(
                data: (isConnected) => Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.white : Colors.red[200],
                  size: 20,
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                error: (_, __) => Icon(Icons.wifi_off, color: Colors.red[200], size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: LoadingIndicator(
          message: 'Saving video...',
          color: AppColors.primaryGreen,
        ),
      )
          : SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Connection status banner
              networkStatus.when(
                data: (isConnected) => !isConnected
                    ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isEditing ? Icons.edit : Icons.video_library,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? 'Edit Educational Video' : 'Add New Educational Video',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isEditing
                                          ? 'Update video information and settings'
                                          : 'Share educational content with the farming community',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form Fields
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Video Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

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
                              const SizedBox(height: 20),

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
                              const SizedBox(height: 20),

                              // Description
                              CustomInputField(
                                controller: _descriptionController,
                                label: 'Description *',
                                hint: 'Enter video description...',
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Description is required';
                                  }
                                  if (value.length > 500) {
                                    return 'Description must be less than 500 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Category and Duration Row
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(
                                      labelText: 'Category *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    items: _buildCategoryItems(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomInputField(
                                    controller: _durationController,
                                    label: 'Duration',
                                    hint: 'e.g., 5:30, 12:45',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Custom Thumbnail URL (Optional)
                              CustomInputField(
                                controller: _thumbnailUrlController,
                                label: 'Custom Thumbnail URL (Optional)',
                                hint: 'Leave empty to use auto-generated thumbnail',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Preview Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: _buildPreviewSection(),
                      ),

                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  isEditing ? 'Update Video' : 'Add Video',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor(_selectedCategory).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatCategoryDisplayName(_selectedCategory),
                  style: TextStyle(
                    color: _getCategoryColor(_selectedCategory),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thumbnail preview
          if (thumbnailUrl != null)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text('Thumbnail not available', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    if (_durationController.text.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _durationController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Video info preview
          Text(
            _titleController.text.isNotEmpty ? _titleController.text : 'Video Title',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : 'Video description will appear here...',
            style: TextStyle(
              color: _descriptionController.text.isNotEmpty
                  ? Colors.grey[700]
                  : Colors.grey[400],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}