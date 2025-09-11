// lib/features/community/presentation/create_post_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/custom_input_field.dart';
import '../../../core/providers/app_providers.dart';
import 'widgets/location_picker.dart';

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
  Map<String, dynamic>? _selectedLocation;
  List<String> _tags = [];
  bool _isLoading = false;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        _characterCount = _contentController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _handleBackPress(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _canPost() && !_isLoading
                ? () => _createPost(currentUser)
                : null,
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
              'Post',
              style: TextStyle(
                color: _canPost() && !_isLoading
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(currentUser),
                const SizedBox(height: 20),
                _buildContentInput(),
                const SizedBox(height: 20),
                if (_selectedImage != null) _buildImagePreview(),
                if (_selectedLocation != null) _buildLocationDisplay(),
                _buildTagsSection(),
                const SizedBox(height: 30),
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(dynamic currentUser) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreen,
            child: Text(
              currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.displayName ?? 'User',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Public post',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomInputField(
            controller: _contentController,
            hint: 'What\'s happening in your farm today?',
            maxLines: 8,
            maxLength: 500,
            validator: (value) {
              if (value?.trim().isEmpty == true) {
                return 'Please enter some content for your post';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share your farming experience, tips, or questions',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                '$_characterCount/500',
                style: TextStyle(
                  color: _characterCount > 450 ? AppColors.error : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDisplay() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLocation!['name'] ?? 'Selected Location',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  if (_selectedLocation!['address'] != null)
                    Text(
                      _selectedLocation!['address'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = null;
                });
              },
              child: Icon(
                Icons.close,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map((tag) => _buildTagChip(tag, true)),
              _buildAddTagChip(),
            ],
          ),
          if (_tags.isEmpty)
            Text(
              'Add tags to help others discover your post',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryGreen : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
              child: Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddTagChip() {
    return GestureDetector(
      onTap: _showAddTagDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryGreen),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(width: 4),
            Text(
              'Add tag',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.photo_camera,
              label: 'Photo',
              onTap: _pickImage,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.location_on,
              label: 'Location',
              onTap: _showLocationPicker,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canPost() {
    return _contentController.text.trim().isNotEmpty;
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPicker(
        onLocationSelected: (location) {
          setState(() {
            _selectedLocation = location;
          });
        },
        initialLocation: _selectedLocation,
      ),
    );
  }

  void _showAddTagDialog() {
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: tagController,
          decoration: const InputDecoration(
            hintText: 'Enter tag name (without #)',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && !_tags.contains(value.trim().toLowerCase())) {
              setState(() {
                _tags.add(value.trim().toLowerCase());
              });
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final tag = tagController.text.trim().toLowerCase();
              if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
                setState(() {
                  _tags.add(tag);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }


  Future<void> _createPost(dynamic currentUser) async {
    final networkStatus = ref.read(networkStatusProvider);

    networkStatus.when(
      data: (isOnline) async {
        if (!isOnline) {
          _showError('Cannot create post while offline');
          return;
        }
        if (!_formKey.currentState!.validate() || currentUser == null) {
          return;
        }

        setState(() {
          _isLoading = true;
        });

        try {
          final communityRepository = ref.read(communityRepositoryProvider);

          await communityRepository.createPost(
            content: _contentController.text.trim(),
            authorId: currentUser.uid,
            authorName: currentUser.displayName ?? 'User',
            authorAvatar: currentUser.photoURL ?? '',
            imageFile: _selectedImage,
            location: _selectedLocation?['name'],
            tags: _tags,

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
          _showError('Failed to create post: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      loading: () => setState(() {
        _isLoading = true;
      }),
      error: (_, __) => _showError('Network status unknown'),
    );


  }


  void _handleBackPress() {
    if (_contentController.text.trim().isNotEmpty ||
        _selectedImage != null ||
        _selectedLocation != null ||
        _tags.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Post?'),
          content: const Text('Are you sure you want to discard this post? Your changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}