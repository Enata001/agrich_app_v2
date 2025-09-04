import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/gradient_background.dart';

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildDailyTipSection(),
            _buildCategoryTabs(),
            Expanded(
              child: _buildTipsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'Daily Tips',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showFavorites(),
              icon: const Icon(Icons.favorite, color: Colors.white),
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
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Today\'s Tip',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _toggleFavorite('daily_tip'),
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Water your crops early in the morning to reduce evaporation and give plants time to dry before evening, preventing fungal diseases.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Irrigation',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      'All', 'Planting', 'Irrigation', 'Pest Control',
      'Fertilization', 'Weather', 'Harvesting'
    ];

    return Container(
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
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
    );
  }

  Widget _buildTipsList() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          color: AppColors.primaryGreen,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _getMockTips().length,
            itemBuilder: (context, index) {
              final tip = _getMockTips()[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildTipCard(tip),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(tip['category']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(tip['category']),
                    color: _getCategoryColor(tip['category']),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'] ?? 'Farming Tip',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip['content'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleFavorite(tip['id']),
                  icon: Icon(
                    tip['isFavorite'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: tip['isFavorite'] == true
                        ? Colors.red
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(tip['category']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tip['category'] ?? 'General',
                    style: TextStyle(
                      color: _getCategoryColor(tip['category']),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tip['likes'] ?? 0}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Text(
                  tip['date'] ?? 'Today',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Planting':
        return Colors.green;
      case 'Irrigation':
        return Colors.blue;
      case 'Pest Control':
        return Colors.red;
      case 'Fertilization':
        return Colors.orange;
      case 'Weather':
        return Colors.purple;
      case 'Harvesting':
        return Colors.amber;
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Planting':
        return Icons.eco;
      case 'Irrigation':
        return Icons.water_drop;
      case 'Pest Control':
        return Icons.bug_report;
      case 'Fertilization':
        return Icons.grass;
      case 'Weather':
        return Icons.cloud;
      case 'Harvesting':
        return Icons.agriculture;
      default:
        return Icons.lightbulb;
    }
  }

  void _showFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorite tips feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _toggleFavorite(String? tipId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tip saved to favorites!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  List<Map<String, dynamic>> _getMockTips() {
    return [
      {
        'id': '1',
        'title': 'Best Time for Seed Planting',
        'content': 'Plant seeds 2-3 weeks after the last frost date in your area. Soil temperature should be consistently above 60°F for optimal germination.',
        'category': 'Planting',
        'likes': 45,
        'date': '2 days ago',
        'isFavorite': false,
      },
      {
        'id': '2',
        'title': 'Natural Pest Deterrent',
        'content': 'Mix neem oil with water (2 tablespoons per gallon) and spray on plants early morning or evening to deter insects without harmful chemicals.',
        'category': 'Pest Control',
        'likes': 67,
        'date': '3 days ago',
        'isFavorite': true,
      },
      {
        'id': '3',
        'title': 'Soil pH Testing',
        'content': 'Test your soil pH monthly. Most crops prefer pH 6.0-7.0. Add lime to raise pH or sulfur to lower it gradually over time.',
        'category': 'Fertilization',
        'likes': 32,
        'date': '1 week ago',
        'isFavorite': false,
      },
      {
        'id': '4',
        'title': 'Weather Pattern Awareness',
        'content': 'Check 7-day weather forecasts before major farming activities. Avoid harvesting 24 hours before expected rain to prevent crop damage.',
        'category': 'Weather',
        'likes': 89,
        'date': '4 days ago',
        'isFavorite': false,
      },
      {
        'id': '5',
        'title': 'Proper Harvesting Time',
        'content': 'Harvest vegetables early morning when they\'re fully hydrated. This ensures better flavor, longer shelf life, and maximum nutritional value.',
        'category': 'Harvesting',
        'likes': 78,
        'date': '5 days ago',
        'isFavorite': true,
      },
      {
        'id': '6',
        'title': 'Efficient Water Management',
        'content': 'Use drip irrigation or soaker hoses to reduce water waste by up to 50%. Water deeply but less frequently to encourage deep root growth.',
        'category': 'Irrigation',
        'likes': 56,
        'date': '1 week ago',
        'isFavorite': false,
      },
    ];
  }
}