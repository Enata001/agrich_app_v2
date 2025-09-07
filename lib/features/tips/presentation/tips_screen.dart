
import 'package:agrich_app_v2/features/tips/presentation/widgets/tip_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/custom_input_field.dart';
import 'providers/tips_provider.dart';
import 'widgets/daily_tip_card.dart';
import 'widgets/tip_card.dart';
import 'widgets/tip_shimmer.dart';

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final categories = ref.watch(tipsCategoriesProvider);
    final tips = _selectedCategory == 'all'
        ? ref.watch(allTipsProvider)
        : ref.watch(tipsByCategoryProvider(_selectedCategory));

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 330.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        // Fixed header section
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        // Collapsible featured tip section
                        Flexible(
                          child: _buildDailyTipSection(),
                        ),
                      ],
                    ),
                  ),
                  titlePadding: EdgeInsets.zero,
                  centerTitle: false,
                ),
              ),

              // Search Bar (when active)
              if (_showSearch)
                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),

              // Category Tabs
              SliverToBoxAdapter(
                child: categories.when(
                  data: (cats) => _buildCategoryTabs(cats),
                  loading: () => const SizedBox(height: 60),
                  error: (_, _) => const SizedBox(),
                ),
              ),

              // Tips List
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: tips.when(
                    data: (tipsList) {
                      final filteredTips = _filterTips(tipsList);

                      if (filteredTips.isEmpty) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => _refreshTips(),
                        color: AppColors.primaryGreen,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            ...filteredTips.asMap().entries.map((entry) {
                              final index = entry.key;
                              final tip = entry.value;
                              return FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                delay: Duration(milliseconds: index * 50),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: TipCard(
                                    tip: tip,
                                    onTap: () => _viewTipDetails(tip),
                                    onSave: () => _toggleSaveTip(tip),
                                    onLike: () => _toggleLikeTip(tip),
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      );
                    },
                    loading: () => Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _buildLoadingState(),
                    ),
                    error: (error, stack) => Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _buildErrorState(error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lightbulb,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Tips',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Expert farming advice',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _showSearch = !_showSearch),
              icon: Icon(
                _showSearch ? Icons.close : Icons.search,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTipSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Featured Tip",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const DailyTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: CustomInputField(
          controller: _searchController,
          hint: 'Search tips...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
            ref.invalidate(searchTipsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              final isSelected = _selectedCategory == category;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      _formatCategoryName(category),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  _searchQuery.isNotEmpty || _selectedCategory != 'all'
                      ? Icons.search_off
                      : Icons.lightbulb_outline,
                  size: 60,
                  color: AppColors.primaryGreen.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No tips found'
                    : _selectedCategory != 'all'
                    ? 'No tips in this category'
                    : 'No tips available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching with different keywords'
                    : 'Check back later for new farming tips',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: const TipCardShimmer(),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'Unable to load tips',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your connection and try again',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _refreshTips(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 600),
      child: FloatingActionButton(
        onPressed: () {
          // Scroll to top functionality could be implemented with a ScrollController if needed
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
      ),
    );
  }

  // Helper Methods
  List<Map<String, dynamic>> _filterTips(List<Map<String, dynamic>> tips) {
    if (_searchQuery.isEmpty) return tips;

    return tips.where((tip) {
      final title = (tip['title'] as String? ?? '').toLowerCase();
      final content = (tip['content'] as String? ?? '').toLowerCase();
      final category = (tip['category'] as String? ?? '').toLowerCase();

      return title.contains(_searchQuery) ||
          content.contains(_searchQuery) ||
          category.contains(_searchQuery);
    }).toList();
  }

  String _formatCategoryName(String category) {
    if (category == 'all') return 'All';
    return category.split(' ').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Future<void> _refreshTips() async {
    ref.invalidate(allTipsProvider);
    ref.invalidate(tipsByCategoryProvider);
    ref.invalidate(dailyTipProvider);
    ref.invalidate(tipsCategoriesProvider);
    await Future.delayed(const Duration(seconds: 1));
  }

  void _viewTipDetails(Map<String, dynamic> tip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TipDetailsModal(tip: tip),
    );
  }

  void _toggleSaveTip(Map<String, dynamic> tip) {
    final tipId = tip['id'] as String;
    ref.read(tipsRepositoryProvider).saveTip(tipId, 'current_user_id');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tip ${tip['isSaved'] ? 'removed from' : 'saved to'} bookmarks'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _toggleLikeTip(Map<String, dynamic> tip) {
    final tipId = tip['id'] as String;
    ref.read(tipsRepositoryProvider).likeTip(tipId, 'current_user_id');
  }

  void _showSavedTips() {
    context.push('/saved-tips');
  }
}