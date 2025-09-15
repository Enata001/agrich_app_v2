import 'package:agrich_app_v2/core/router/app_router.dart';
import 'package:agrich_app_v2/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_input_field.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_bulk_actions_bar.dart';
import '../widgets/admin_tip_form_dialog.dart';


class AdminTipsScreen extends ConsumerStatefulWidget {
  const AdminTipsScreen({super.key});

  @override
  ConsumerState<AdminTipsScreen> createState() => _AdminTipsScreenState();
}

class _AdminTipsScreenState extends ConsumerState<AdminTipsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConfig.tipCategories.length + 1,
      vsync: this,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final category = _tabController.index == 0
            ? ''
            : AppConfig.tipCategories[_tabController.index - 1];
        ref.read(tipsCategoryFilterProvider.notifier).state = category;
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
    final tipsAsync = ref.watch(filteredAdminTipsProvider);
    final selectedTips = ref.watch(selectedTipsProvider);
    final isTablet = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, tipsAsync),
      body: Column(
        children: [
          // Search and Filters
          _buildSearchAndFilters(context),

          // Bulk Actions Bar
          if (selectedTips.isNotEmpty)
            AdminBulkActionsBar(
              selectedCount: selectedTips.length,
              onSelectAll: () => _selectAllTips(tipsAsync),
              onClearSelection: () => ref.read(selectedTipsProvider.notifier).clearAll(),
              onBulkDelete: () => _bulkDeleteTips(selectedTips.toList()),
              onBulkCategoryChange: () => _bulkChangeTipCategory(selectedTips.toList()),
            ),

          // Tips List
          Expanded(
            child: tipsAsync.when(
              data: (tips) => tips.isEmpty
                  ? _buildEmptyState(context)
                  : _buildTipsList(context, tips, isTablet),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTipDialog(context),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Tip'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AsyncValue<List<Map<String, dynamic>>> tipsAsync) {
    final tipCount = tipsAsync.whenOrNull(data: (tips) => tips.length) ?? 0;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),

          ),
          Text(
            '$tipCount tips',
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
          onPressed: () => ref.invalidate(adminTipsProvider),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        // Import/Export menu

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
              hint: 'Search tips by title, content, or category...',
              prefixIcon: Icon(Icons.search),
              onChanged: (value) {
                ref.read(tipsSearchQueryProvider.notifier).state = value;
              },
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(tipsSearchQueryProvider.notifier).state = '';
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
              ...AppConfig.tipCategories.map((category) => Tab(
                text: category.split(' ').map((word) =>
                word.substring(0, 1).toUpperCase() + word.substring(1)).join(' '),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList(BuildContext context, List<Map<String, dynamic>> tips, bool isTablet) {
    if (isTablet) {
      return _buildTipsGrid(context, tips);
    } else {
      return _buildTipsMobileList(context, tips);
    }
  }

  Widget _buildTipsGrid(BuildContext context, List<Map<String, dynamic>> tips) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return _buildTipCard(tips[index]);
      },
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    final selectedTips = ref.watch(selectedTipsProvider);
    final isSelected = selectedTips.contains(tip['id']);
    final createdAt = tip['createdAt']?.toDate() ?? DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSelected
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditTipDialog(context, tip),
          onLongPress: () => ref.read(selectedTipsProvider.notifier).toggle(tip['id']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with selection and category
                Row(
                  children: [
                    if (isSelected)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      )
                    else
                      GestureDetector(
                        onTap: () => ref.read(selectedTipsProvider.notifier).toggle(tip['id']),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(tip['category']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (tip['category'] ?? 'general').toUpperCase(),
                        style: TextStyle(
                          color: _getCategoryColor(tip['category']),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  tip['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Content preview
                Text(
                  tip['content'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // Metadata
                Row(
                  children: [
                    Icon(
                      _getDifficultyIcon(tip['difficulty']),
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (tip['difficulty'] ?? 'beginner').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditTipDialog(context, tip),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _deleteTip(tip['id'], tip['title']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      child: const Icon(Icons.delete, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsMobileList(BuildContext context, List<Map<String, dynamic>> tips) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        final selectedTips = ref.watch(selectedTipsProvider);
        final isSelected = selectedTips.contains(tip['id']);
        final createdAt = tip['createdAt']?.toDate() ?? DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isSelected
                ? Border.all(color: AppColors.primaryGreen, width: 2)
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: GestureDetector(
              onTap: () => ref.read(selectedTipsProvider.notifier).toggle(tip['id']),
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
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    tip['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(tip['category']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (tip['category'] ?? 'general').toUpperCase(),
                    style: TextStyle(
                      color: _getCategoryColor(tip['category']),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  tip['content'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _getDifficultyIcon(tip['difficulty']),
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (tip['difficulty'] ?? 'beginner').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleTipAction(value, tip),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 20),
                      SizedBox(width: 8),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showEditTipDialog(context, tip),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final category = ref.watch(tipsCategoryFilterProvider);
    final searchQuery = ref.watch(tipsSearchQueryProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No tips found for "$searchQuery"'
                : category.isNotEmpty
                ? 'No tips found in $category category'
                : 'No tips found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || category.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Create your first farming tip to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateTipDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create First Tip'),
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
            'Failed to load tips',
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
            onPressed: () => ref.invalidate(adminTipsProvider),
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

  // Helper methods
  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'planting':
        return Colors.green;
      case 'water management':
        return Colors.blue;
      case 'soil care':
        return Colors.brown;
      case 'fertilization':
        return Colors.orange;
      case 'pest control':
        return Colors.red;
      case 'harvesting':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return Icons.star_outline;
      case 'intermediate':
        return Icons.star_half;
      case 'advanced':
        return Icons.star;
      default:
        return Icons.star_outline;
    }
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'import':
        _showImportDialog();
        break;
      case 'export':
        _exportTips();
        break;
      case 'template':
        _downloadTemplate();
        break;
    }
  }

  void _handleTipAction(String action, Map<String, dynamic> tip) {
    switch (action) {
      case 'edit':
        _showEditTipDialog(context, tip);
        break;
      case 'duplicate':
        _duplicateTip(tip);
        break;
      case 'delete':
        _deleteTip(tip['id'], tip['title']);
        break;
    }
  }

  void _showCreateTipDialog(BuildContext context) {
    // showDialog(
    //   context: context,
    //   builder: (context) => AdminTipFormDialog(
    //     onSave: _createTip,
    //   ),
    // );
    AppRouter.push(AppRoutes.adminTipCreate, extra: {
      'onSave': _createTip,
    });

  }

  void _showEditTipDialog(BuildContext context, Map<String, dynamic> tip) {
    // showDialog(
    //   context: context,
    //   builder: (context) => AdminTipFormDialog(
    //     tip: tip,
    //     onSave: (tipData) => _updateTip(tip['id'], tipData),
    //   ),
    // );
    AppRouter.push(AppRoutes.adminTipEdit, extra: {
      'tip': tip,
      'onSave': (tipData) => _updateTip(tip['id'], tipData),
    });
  }

  Future<void> _createTip(Map<String, dynamic> tipData) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.createTip(tipData, adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip "${tipData['title']}" created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create tip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateTip(String tipId, Map<String, dynamic> tipData) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.updateTip(tipId, tipData, adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip "${tipData['title']}" updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update tip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteTip(String tipId, String? title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tip'),
        content: Text('Are you sure you want to delete "${title ?? 'this tip'}"?'),
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
      await adminRepository.deleteTip(tipId, adminId);

      // Remove from selection if selected
      ref.read(selectedTipsProvider.notifier).remove(tipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip "${title ?? 'Untitled'}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete tip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _duplicateTip(Map<String, dynamic> tip) async {
    final tipData = Map<String, dynamic>.from(tip);
    tipData['title'] = '${tipData['title']} (Copy)';
    tipData.remove('id');
    tipData.remove('createdAt');
    tipData.remove('updatedAt');

    await _createTip(tipData);
  }

  void _selectAllTips(AsyncValue<List<Map<String, dynamic>>> tipsAsync) {
    tipsAsync.whenData((tips) {
      final tipIds = tips.map((tip) => tip['id'] as String).toList();
      ref.read(selectedTipsProvider.notifier).selectAll(tipIds);
    });
  }

  void _bulkDeleteTips(List<String> tipIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tips'),
        content: Text('Are you sure you want to delete ${tipIds.length} selected tips?'),
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
      await adminRepository.bulkDeleteTips(tipIds, adminId);

      // Clear selection
      ref.read(selectedTipsProvider.notifier).clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tipIds.length} tips deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete tips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _bulkChangeTipCategory(List<String> tipIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select new category for ${tipIds.length} selected tips:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              items: AppConfig.tipCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.split(' ').map((word) =>
                  word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ')),
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
        _performBulkCategoryChange(tipIds, newCategory);
      }
    });
  }

  void _performBulkCategoryChange(List<String> tipIds, String newCategory) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.bulkUpdateTipCategory(tipIds, newCategory, adminId);

      // Clear selection
      ref.read(selectedTipsProvider.notifier).clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tipIds.length} tips moved to $newCategory category'),
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

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Tips'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import tips from CSV file'),
            SizedBox(height: 8),
            Text('Format: title, content, category, difficulty, estimatedTime, tools, benefits'),
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
              // Implement file picker and import logic
              _performImport();
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  void _exportTips() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting tips...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    // Implement export logic
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Downloading CSV template...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    // Implement template download logic
  }

  void _performImport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Import functionality coming soon...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    // Implement actual import logic
  }
}