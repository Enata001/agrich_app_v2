import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AdminBulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onBulkDelete;
  final VoidCallback? onBulkCategoryChange;
  final VoidCallback? onBulkEdit;

  const AdminBulkActionsBar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onBulkDelete,
    this.onBulkCategoryChange,
    this.onBulkEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedCount selected',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),

          // Select All / Clear Selection
          TextButton(
            onPressed: onSelectAll,
            child: const Text('Select All'),
          ),
          TextButton(
            onPressed: onClearSelection,
            child: const Text('Clear'),
          ),

          const Spacer(),

          // Bulk Actions
          Row(
            children: [
              if (onBulkCategoryChange != null)
                IconButton(
                  onPressed: onBulkCategoryChange,
                  icon: const Icon(Icons.category),
                  tooltip: 'Change Category',
                ),
              if (onBulkEdit != null)
                IconButton(
                  onPressed: onBulkEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Bulk Edit',
                ),
              IconButton(
                onPressed: onBulkDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete Selected',
              ),
            ],
          ),
        ],
      ),
    );
  }
}