import 'package:agrich_app_v2/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/utils.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_input_field.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_video_form_dialog.dart' hide CustomInputField;
import '../widgets/admin_bulk_actions_bar.dart';

class AdminVideosScreen extends ConsumerStatefulWidget {
  const AdminVideosScreen({super.key});

  @override
  ConsumerState<AdminVideosScreen> createState() => _AdminVideosScreenState();
}

class _AdminVideosScreenState extends ConsumerState<AdminVideosScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConfig.videoCategories.length + 1,
      vsync: this,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final category = _tabController.index == 0
            ? ''
            : AppConfig.videoCategories[_tabController.index - 1];
        ref.read(videosCategoryFilterProvider.notifier).state = category;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(filteredAdminVideosProvider);
    final selectedVideos = ref.watch(selectedVideosProvider);
    final isTablet = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, videosAsync),
      body: Column(
        children: [
          // Search and Filters
          _buildSearchAndFilters(context),

          // Bulk Actions Bar
          if (selectedVideos.isNotEmpty)
            AdminBulkActionsBar(
              selectedCount: selectedVideos.length,
              onSelectAll: () => _selectAllVideos(videosAsync),
              onClearSelection: () => ref.read(selectedVideosProvider.notifier).clearAll(),
              onBulkDelete: () => _bulkDeleteVideos(selectedVideos.toList()),
              onBulkCategoryChange: () => _bulkChangeVideoCategory(selectedVideos.toList()),
            ),

          // Videos List
          Expanded(
            child: videosAsync.when(
              data: (videos) => videos.isEmpty
                  ? _buildEmptyState(context)
                  : _buildVideosList(context, videos, isTablet),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVideoDialog(context),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Video'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AsyncValue<List<Map<String, dynamic>>> videosAsync) {
    final videoCount = videosAsync.whenOrNull(data: (videos) => videos.length) ?? 0;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '$videoCount videos',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Refresh button
        IconButton(
          onPressed: () => ref.invalidate(adminVideosProvider),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomInputField(
              controller: _searchController,
              hint: 'Search videos by title, description, or category...',
              prefixIcon: Icon(Icons.search),
              onChanged: (value) {
                ref.read(videosSearchQueryProvider.notifier).state = value;
              },
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(videosSearchQueryProvider.notifier).state = '';
                },
                icon: const Icon(Icons.clear),
              )
                  : null,
            ),
          ),

          // Category Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3,
            tabs: [
              const Tab(text: 'All Categories'),
              ...AppConfig.videoCategories.map((category) => Tab(text: category)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList(BuildContext context, List<Map<String, dynamic>> videos, bool isTablet) {
    if (isTablet) {
      return _buildVideosGrid(context, videos);
    } else {
      return _buildVideosMobileList(context, videos);
    }
  }

  Widget _buildVideosGrid(BuildContext context, List<Map<String, dynamic>> videos) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _buildVideoCard(videos[index]);
      },
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final selectedVideos = ref.watch(selectedVideosProvider);
    final isSelected = selectedVideos.contains(video['id']);
    final createdAt = video['createdAt']?.toDate() ?? DateTime.now();
    final views = video['views'] ?? 0;
    final likes = video['likes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSelected
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox + Thumbnail
              Column(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(selectedVideosProvider.notifier).toggle(video['id']),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGreen : null,
                        border: isSelected ? null : Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          if (video['thumbnailUrl']?.isNotEmpty == true)
                            CachedNetworkImage(
                              imageUrl: video['thumbnailUrl'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorWidget: (context, url, error) => const Icon(Icons.video_library),
                            )
                          else
                            const Icon(Icons.video_library),
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            video['category'] ?? 'General',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (video['duration'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            video['duration'],
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${_formatCount(views)} views',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${_formatCount(likes)} likes',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const Spacer(),
                        Text(timeago.format(createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleVideoAction(value, video),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'preview', child: Text('Preview')),
                  const PopupMenuItem(value: 'analytics', child: Text('Analytics')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideosMobileList(BuildContext context, List<Map<String, dynamic>> videos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final selectedVideos = ref.watch(selectedVideosProvider);
        final isSelected = selectedVideos.contains(video['id']);
        final createdAt = video['createdAt']?.toDate() ?? DateTime.now();
        final views = video['views'] ?? 0;
        final likes = video['likes'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isSelected
                ? Border.all(color: AppColors.primaryGreen, width: 2)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Checkbox + Thumbnail
              Column(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(selectedVideosProvider.notifier).toggle(video['id']),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGreen : null,
                        border: isSelected ? null : Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          if (video['thumbnailUrl']?.isNotEmpty == true)
                            CachedNetworkImage(
                              imageUrl: video['thumbnailUrl'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorWidget: (context, url, error) => const Icon(Icons.video_library),
                            )
                          else
                            const Icon(Icons.video_library),
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Middle: Title + Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            video['category'] ?? 'General',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (video['duration'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            video['duration'],
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${_formatCount(views)} views',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${_formatCount(likes)} likes',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const Spacer(),
                        Text(timeago.format(createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Popup Menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleVideoAction(value, video),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'preview', child: Text('Preview')),
                  const PopupMenuItem(value: 'analytics', child: Text('Analytics')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final category = ref.watch(videosCategoryFilterProvider);
    final searchQuery = ref.watch(videosSearchQueryProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No videos found for "$searchQuery"'
                : category.isNotEmpty
                ? 'No videos found in $category category'
                : 'No videos found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || category.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Add your first educational video to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateVideoDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Failed to load videos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(adminVideosProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
        ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'bulk_upload':
        _showBulkUploadDialog();
        break;
      case 'export':
        _exportVideos();
        break;
      case 'analytics':
        _showAnalytics();
        break;
    }
  }

  void _handleVideoAction(String action, Map<String, dynamic> video) {
    switch (action) {
      case 'edit':
        _showEditVideoDialog(context, video);
        break;
      case 'preview':
        _previewVideo(video);
        break;
      case 'analytics':
        _showVideoAnalytics(video);
        break;
      case 'delete':
        _deleteVideo(video['id'], video['title']);
        break;
    }
  }

  void _showCreateVideoDialog(BuildContext context) {
    AppRouter.push(AppRoutes.adminVideoCreate, extra: {
      'onSave': _createVideo
    });
  }

  void _showEditVideoDialog(BuildContext context, Map<String, dynamic> video) {
        AppRouter.push(AppRoutes.adminVideoEdit, extra: {
          'video': video,
          'onSave': (videoData) => _updateVideo(video['id'], videoData),
        });
  }

  void _createVideo(Map<String, dynamic> videoData) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.createVideo(videoData, adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video "${videoData['title']}" created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateVideo(String videoId, Map<String, dynamic> videoData) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.updateVideo(videoId, videoData, adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video "${videoData['title']}" updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteVideo(String videoId, String? title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${title ?? 'this video'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.deleteVideo(videoId, adminId);

      // Remove from selection if selected
      ref.read(selectedVideosProvider.notifier).remove(videoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video "${title ?? 'Untitled'}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previewVideo(Map<String, dynamic> video) {
    final youtubeUrl = video['youtubeUrl'] ?? '';
    if (youtubeUrl.isNotEmpty) {
      // Launch YouTube URL in browser or show preview dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening ${video['title']}...'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video URL available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _selectAllVideos(AsyncValue<List<Map<String, dynamic>>> videosAsync) {
    videosAsync.whenData((videos) {
      final videoIds = videos.map((video) => video['id'] as String).toList();
      ref.read(selectedVideosProvider.notifier).selectAll(videoIds);
    });
  }

  void _bulkDeleteVideos(List<String> videoIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Videos'),
        content: Text('Are you sure you want to delete ${videoIds.length} selected videos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.bulkDeleteVideos(videoIds, adminId);

      // Clear selection
      ref.read(selectedVideosProvider.notifier).clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${videoIds.length} videos deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _bulkChangeVideoCategory(List<String> videoIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select new category for ${videoIds.length} selected videos:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              items: AppConfig.videoCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop(value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((newCategory) {
      if (newCategory != null) {
        _performBulkCategoryChange(videoIds, newCategory);
      }
    });
  }

  void _performBulkCategoryChange(List<String> videoIds, String newCategory) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);

      // Update each video individually since we don't have a bulk update method for videos
      for (final videoId in videoIds) {
        await adminRepository.updateVideo(videoId, {'category': newCategory}, adminId);
      }

      // Clear selection
      ref.read(selectedVideosProvider.notifier).clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${videoIds.length} videos moved to $newCategory category'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBulkUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Upload Videos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload multiple videos from CSV file'),
            SizedBox(height: 8),
            Text('Format: title, description, category, youtubeUrl, thumbnailUrl, duration'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkUpload();
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  void _exportVideos() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting videos...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    // Implement export logic
  }

  void _showAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Video analytics coming soon...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    // Implement analytics view
  }

  void _showVideoAnalytics(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analytics: ${video['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticRow('Views', '${_formatCount(video['views'] ?? 0)}'),
            _buildAnalyticRow('Likes', '${_formatCount(video['likes'] ?? 0)}'),
            _buildAnalyticRow('Comments', '${video['commentsCount'] ?? 0}'),
            _buildAnalyticRow('Duration', video['duration'] ?? 'Unknown'),
            _buildAnalyticRow('Category', video['category'] ?? 'General'),
            _buildAnalyticRow('Created',
                video['createdAt'] != null
                    ? DateFormat('MMM dd, yyyy').format(video['createdAt'].toDate())
                    : 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _performBulkUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bulk upload functionality coming soon...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    // Implement actual bulk upload logic
  }
}