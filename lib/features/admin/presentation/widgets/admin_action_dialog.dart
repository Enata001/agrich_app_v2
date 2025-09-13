import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_input_field.dart';

class AdminActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String actionText;
  final Color actionColor;
  final bool requiresReason;
  final Function(String reason) onConfirm;

  const AdminActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actionText,
    required this.actionColor,
    this.requiresReason = false,
    required this.onConfirm,
  });

  @override
  State<AdminActionDialog> createState() => _AdminActionDialogState();
}

class _AdminActionDialogState extends State<AdminActionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: widget.actionColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          if (widget.requiresReason) ...[
            const SizedBox(height: 16),
            CustomInputField(
              controller: _reasonController,
              label: 'Reason (required)',
              hint: 'Enter the reason for this action...',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Reason is required';
                }
                return null;
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.actionColor,
            foregroundColor: Colors.white,
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
              : Text(widget.actionText),
        ),
      ],
    );
  }

  void _handleConfirm() async {
    if (widget.requiresReason && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm(_reasonController.text.trim());
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
            content: Text('Action failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}