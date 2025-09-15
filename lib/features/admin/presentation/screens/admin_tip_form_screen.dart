import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/network_service.dart';
import '../../../shared/widgets/custom_input_field.dart';
import '../../../shared/widgets/loading_indicator.dart';

class AdminTipFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? tip;
  final Function(Map<String, dynamic>) onSave;

  const AdminTipFormScreen({
    super.key,
    this.tip,
    required this.onSave,
  });

  @override
  ConsumerState<AdminTipFormScreen> createState() => _AdminTipFormScreenState();
}

class _AdminTipFormScreenState extends ConsumerState<AdminTipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _estimatedTimeController = TextEditingController();
  final TextEditingController _toolsController = TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'general';
  String _selectedDifficulty = 'beginner';
  bool _isLoading = false;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    if (widget.tip != null) {
      _populateFields(widget.tip!);
    }
    _checkNetworkStatus();
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

  void _populateFields(Map<String, dynamic> tip) {
    _titleController.text = tip['title'] ?? '';
    _contentController.text = tip['content'] ?? '';
    _selectedCategory = tip['category'] ?? 'general';
    _selectedDifficulty = tip['difficulty'] ?? 'beginner';
    _estimatedTimeController.text = tip['estimatedTime'] ?? '';

    final tools = tip['tools'] as List<dynamic>? ?? [];
    _toolsController.text = tools.join(', ');

    final benefits = tip['benefits'] as List<dynamic>? ?? [];
    _benefitsController.text = benefits.join(', ');

    final tags = tip['tags'] as List<dynamic>? ?? [];
    _tagsController.text = tags.join(', ');
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
      final tipData = {
        'id': widget.tip?['id'],
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'estimatedTime': _estimatedTimeController.text.trim(),
        'tools': _toolsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'benefits': _benefitsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'tags': _tagsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      };

      await widget.onSave(tipData);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tip: $e'),
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
      case 'planting': return Colors.green;
      case 'watering': return Colors.blue;
      case 'fertilization': return Colors.orange;
      case 'pest_control': return Colors.red;
      case 'harvesting': return Colors.purple;
      case 'soil_management': return Colors.brown;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _estimatedTimeController.dispose();
    _toolsController.dispose();
    _benefitsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tip != null;
    final networkStatus = ref.watch(networkStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Tip' : 'Create New Tip',
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
                error: (_, _) => Icon(Icons.wifi_off, color: Colors.red[200], size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: LoadingIndicator(
          message: 'Saving tip...',
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
                error: (_, _) => const SizedBox.shrink(),
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
                                color: Colors.black.withValues(alpha:0.05),
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
                                  color: AppColors.primaryGreen.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isEditing ? Icons.edit : Icons.lightbulb,
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
                                      isEditing ? 'Edit Farming Tip' : 'Create New Farming Tip',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isEditing
                                          ? 'Update this farming tip with new information'
                                          : 'Share your knowledge with the farming community',
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
                                color: Colors.black.withValues(alpha:0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tip Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Title
                              CustomInputField(
                                controller: _titleController,
                                label: 'Title *',
                                hint: 'Enter tip title...',
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

                              // Content
                              CustomInputField(
                                controller: _contentController,
                                label: 'Content *',
                                hint: 'Enter tip content...',
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Content is required';
                                  }
                                  if (value.length > 500) {
                                    return 'Content must be less than 500 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Category and Difficulty Row
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
                                    items: AppConfig.tipCategories.map((category) {
                                      final formatted = category
                                          .split(' ')
                                          .map((word) =>
                                      word.substring(0, 1).toUpperCase() + word.substring(1))
                                          .join(' ');
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(
                                          formatted,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedDifficulty,
                                    decoration: const InputDecoration(
                                      labelText: 'Difficulty *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    items: ['beginner', 'intermediate', 'advanced'].map((difficulty) {
                                      final formatted =
                                          difficulty[0].toUpperCase() + difficulty.substring(1);
                                      return DropdownMenuItem(
                                        value: difficulty,
                                        child: Text(
                                          formatted,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedDifficulty = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Optional Fields
                              Text(
                                'Additional Information (Optional)',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Estimated Time
                              CustomInputField(
                                controller: _estimatedTimeController,
                                label: 'Estimated Time',
                                hint: 'e.g., 15 minutes, 2 hours, Planning time',
                              ),
                              const SizedBox(height: 16),

                              // Tools
                              CustomInputField(
                                controller: _toolsController,
                                label: 'Tools/Equipment',
                                hint: 'Separate tools with commas (e.g., Shovel, Watering can)',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),

                              // Benefits
                              CustomInputField(
                                controller: _benefitsController,
                                label: 'Benefits',
                                hint: 'Separate benefits with commas (e.g., Better yield, Save time)',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),

                              // Tags
                              CustomInputField(
                                controller: _tagsController,
                                label: 'Tags',
                                hint: 'Separate tags with commas (e.g., organic, sustainability)',
                                maxLines: 2,
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
              color: Colors.black.withValues(alpha:0.05),
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
                  isEditing ? 'Update Tip' : 'Create Tip',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
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
                  color: _getCategoryColor(_selectedCategory).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedCategory.toUpperCase(),
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

          // Title Preview
          Text(
            _titleController.text.isNotEmpty ? _titleController.text : 'Tip Title',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Content Preview
          Text(
            _contentController.text.isNotEmpty
                ? _contentController.text
                : 'Tip content will appear here...',
            style: TextStyle(
              color: _contentController.text.isNotEmpty
                  ? Colors.grey[800]
                  : Colors.grey[400],
              height: 1.4,
            ),
          ),

          if (_estimatedTimeController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  _estimatedTimeController.text,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Difficulty indicator
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '${_selectedDifficulty.substring(0, 1).toUpperCase()}${_selectedDifficulty.substring(1)} Level',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}