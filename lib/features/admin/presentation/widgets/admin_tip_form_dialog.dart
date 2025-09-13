import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_input_field.dart';


class AdminTipFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? tip;
  final Function(Map<String, dynamic>) onSave;

  const AdminTipFormDialog({
    super.key,
    this.tip,
    required this.onSave,
  });

  @override
  ConsumerState<AdminTipFormDialog> createState() => _AdminTipFormDialogState();
}

class _AdminTipFormDialogState extends ConsumerState<AdminTipFormDialog> {
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

  @override
  void initState() {
    super.initState();
    if (widget.tip != null) {
      _populateFields(widget.tip!);
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 700 ? 600 : null,
        height: MediaQuery.of(context).size.height * 0.9,
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
                  isEditing ? 'Edit Tip' : 'Create New Tip',
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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Category and Difficulty Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder(),
                              ),
                              items: AppConfig.tipCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.split(' ').map((word) =>
                                  word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ')),
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
                            child: DropdownButtonFormField<String>(
                              value: _selectedDifficulty,
                              decoration: const InputDecoration(
                                labelText: 'Difficulty *',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedDifficulty = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
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
                      const SizedBox(height: 20),

                      // Preview Section
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
                      : Text(isEditing ? 'Update Tip' : 'Create Tip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
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
          Row(
            children: [
              const Icon(Icons.preview, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(_selectedCategory).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedCategory.toUpperCase(),
                  style: TextStyle(
                    color: _getCategoryColor(_selectedCategory),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title Preview
          Text(
            _titleController.text.isNotEmpty ? _titleController.text : 'Tip Title',
            style: const TextStyle(
              fontSize: 18,
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
              color: _contentController.text.isNotEmpty ? Colors.black87 : Colors.grey[500],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Metadata
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildPreviewChip(
                Icons.school,
                _selectedDifficulty.toUpperCase(),
                _getDifficultyColor(_selectedDifficulty),
              ),
              if (_estimatedTimeController.text.isNotEmpty)
                _buildPreviewChip(
                  Icons.access_time,
                  _estimatedTimeController.text,
                  Colors.blue,
                ),
              if (_toolsController.text.isNotEmpty)
                _buildPreviewChip(
                  Icons.build,
                  '${_toolsController.text.split(',').length} tools',
                  Colors.orange,
                ),
              if (_benefitsController.text.isNotEmpty)
                _buildPreviewChip(
                  Icons.star,
                  '${_benefitsController.text.split(',').length} benefits',
                  Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tipData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'estimatedTime': _estimatedTimeController.text.trim(),
        'tools': _toolsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'benefits': _benefitsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'tags': _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'priority': 5, // Default priority
        'author': 'Admin',
        'authorId': 'admin',
      };

      await widget.onSave(tipData);

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
            content: Text('Failed to save tip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
