import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../shared/widgets/gradient_background.dart';

class VideosMainScreen extends ConsumerStatefulWidget {
  const VideosMainScreen({super.key});

  @override
  ConsumerState<VideosMainScreen> createState() => _VideosMainScreenState();
}

class _VideosMainScreenState extends ConsumerState<VideosMainScreen>
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
            _buildCategoryFilter(),
            Expanded(
              child: _buildVideosList(),
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
            const Icon(Icons.play_circle, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'Educational Videos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showSearchDialog(context),
              icon: const Icon(Icons.search, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ...AppConfig.videoCategories];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.3),
                      ),
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
      ),
    );
  }

  Widget _buildVideosList() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh videos
            await Future.delayed(const Duration(seconds: 1));
          },
          color: AppColors.primaryGreen,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _getMockVideos().length,
            itemBuilder: (context, index) {
              final video = _getMockVideos()[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildVideoCard(video),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Thumbnail
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryGreen.withValues(alpha: 0.3),
                        AppColors.primaryGreen.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video['duration'] ?? '0:00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Video Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title'] ?? 'Untitled Video',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  video['description'] ?? 'No description available',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        video['category'] ?? 'General',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${video['views'] ?? 0} views',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      video['uploadDate'] ?? 'Today',
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
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Videos'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon!'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockVideos() {
    return [
      {
        'title': 'Modern Irrigation Techniques for Better Yield',
        'description': 'Learn about drip irrigation and smart watering systems that can increase your crop yield by up to 40%.',
        'category': 'Irrigation',
        'duration': '12:45',
        'views': 1250,
        'uploadDate': '2 days ago',
      },
      {
        'title': 'Organic Pest Control Methods',
        'description': 'Natural and effective ways to protect your crops without harmful chemicals.',
        'category': 'Pest Control',
        'duration': '8:30',
        'views': 980,
        'uploadDate': '1 week ago',
      },
      {
        'title': 'Soil Preparation for Maximum Productivity',
        'description': 'Essential steps to prepare your soil for the upcoming planting season.',
        'category': 'Planting',
        'duration': '15:20',
        'views': 2100,
        'uploadDate': '3 days ago',
      },
      {
        'title': 'Smart Farming with Technology',
        'description': 'How to use modern technology and sensors to optimize your farming operations.',
        'category': 'Modern Techniques',
        'duration': '18:45',
        'views': 3200,
        'uploadDate': '5 days ago',
      },
      {
        'title': 'Harvesting Techniques for Better Quality',
        'description': 'Best practices for harvesting that ensure maximum quality and shelf life.',
        'category': 'Harvesting',
        'duration': '10:15',
        'views': 1540,
        'uploadDate': '1 week ago',
      },
    ];
  }
}