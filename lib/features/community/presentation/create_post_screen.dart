import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/gradient_background.dart';
import 'providers/create_post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateCharacterCount);
    _contentController.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _contentController.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final createPostState = ref.watch(createPostProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _handleBackPress(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          if (createPostState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _canPost() ? () => _createPost(currentUser) : null,
              child: Text(
                'Post',
                style: TextStyle(
                  color: _canPost() ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Header
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: _buildUserHeader(context, currentUser),
                  ),

                  const SizedBox(height: 24),

                  // Content Input
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: _buildContentInput(context),
                  ),

                  const SizedBox(height: 24),

                  // Image Selection
                  if (_selectedImage != null) ...[
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: _buildSelectedImage(context),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 600),
                    child: _buildActionButtons(context),
                  ),

                  const SizedBox(height: 24),

                  // Character Counter
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 800),
                    child: _buildCharacterCounter(context),
                  ),

                  const SizedBox(height: 40),

                  // Create Post Button
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 1000),
                    child: _buildCreateButton(context, currentUser, createPostState.isLoading),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, dynamic currentUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            backgroundImage: currentUser?.photoURL != null
                ? NetworkImage(currentUser!.photoURL!)
                : null,
            child: currentUser?.photoURL == null
                ? Text(
              currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.displayName ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Sharing with community',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Public',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s on your mind?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            maxLines: 8,
            maxLength: AppConfig.maxPostLength,
            decoration: InputDecoration(
              hintText: 'Share your farming tips, experiences, or ask questions...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
              border: InputBorder.none,
              counterText: '', // Hide default counter
            ),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter some content';
              }
              if (value.trim().length < 10) {
                return 'Post content should be at least 10 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Image selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red.shade600,
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to your post',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.image,
                label: 'Photo',
                color: Colors.green,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.location_on,
                label: 'Location',
                color: Colors.red,
                onTap: () => _addLocation(context),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.mood,
                label: 'Feeling',
                color: Colors.orange,
                onTap: () => _addFeeling(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterCounter(BuildContext context) {
    final isOverLimit = _characterCount > AppConfig.maxPostLength;
    final isNearLimit = _characterCount > AppConfig.maxPostLength * 0.8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Character count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          Row(
            children: [
              Text(
                '$_characterCount/${AppConfig.maxPostLength}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOverLimit
                      ? Colors.red
                      : isNearLimit
                      ? Colors.orange
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isNearLimit) ...[
                const SizedBox(width: 8),
                Icon(
                  isOverLimit ? Icons.error : Icons.warning,
                  size: 16,
                  color: isOverLimit ? Colors.red : Colors.orange,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, dynamic currentUser, bool isLoading) {
    return CustomButton(
      text: isLoading ? 'Creating Post...' : 'Create Post',
      onPressed: _canPost() && !isLoading ? () => _createPost(currentUser) : null,
      backgroundColor: _canPost() && !isLoading
          ? AppColors.primaryGreen
          : Colors.grey.shade400,
      textColor: Colors.white,
      icon: isLoading ? null : Icon(Icons.send),
      isLoading: isLoading,
    );
  }

  bool _canPost() {
    return _contentController.text.trim().isNotEmpty &&
        _contentController.text.trim().length >= 10 &&
        _characterCount <= AppConfig.maxPostLength;
  }

  // FIXED: Add missing _createPost method
  Future<void> _createPost(dynamic currentUser) async {
    if (!_formKey.currentState!.validate() || currentUser == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(createPostProvider.notifier).createPost(
        content: _contentController.text.trim(),
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'User',
        authorAvatar: currentUser.photoURL ?? '',
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to community screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addLocation(BuildContext context) {
    // TODO: Implement location picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _addFeeling(BuildContext context) {
    final feelings = [
      {'emoji': '😊', 'text': 'Happy'},
      {'emoji': '😍', 'text': 'Excited'},
      {'emoji': '🤔', 'text': 'Thinking'},
      {'emoji': '😌', 'text': 'Grateful'},
      {'emoji': '💪', 'text': 'Motivated'},
      {'emoji': '🌱', 'text': 'Growing'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How are you feeling?'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3,
            ),
            itemCount: feelings.length,
            itemBuilder: (context, index) {
              final feeling = feelings[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _addFeelingToPost(feeling);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        feeling['emoji']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feeling['text']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addFeelingToPost(Map<String, String> feeling) {
    final currentText = _contentController.text;
    final feelingText = ' — feeling ${feeling['text']!} ${feeling['emoji']!}';

    if (!currentText.contains('feeling')) {
      _contentController.text = currentText + feelingText;
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contentController.text.length),
      );
    }
  }

  void _handleBackPress(BuildContext context) {
    if (_contentController.text.trim().isNotEmpty || _selectedImage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard post?'),
          content: const Text('Are you sure you want to discard this post? Your changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.pop(); // Go back
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }
}