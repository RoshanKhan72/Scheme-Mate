import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feedback_provider.dart';

class FeedbackDialog extends StatefulWidget {
  final String defaultScreen;
  final String defaultType;
  final String? targetId;

  const FeedbackDialog({
    super.key,
    required this.defaultScreen,
    required this.defaultType,
    this.targetId,
  });

  static void show(
    BuildContext context, {
    required String defaultScreen,
    required String defaultType,
    String? targetId,
  }) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(
        defaultScreen: defaultScreen,
        defaultType: defaultType,
        targetId: targetId,
      ),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  late String _selectedType;
  late TextEditingController _screenController;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _typeOptions = {
    'bug': 'Report a Bug 🐛',
    'incorrect_scheme': 'Incorrect Scheme Data ❌',
    'feature_request': 'Suggest a Feature ✨',
    'missing_scheme': 'Suggest a Missing Scheme 📢',
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
    _screenController = TextEditingController(text: widget.defaultScreen);
  }

  @override
  void dispose() {
    _screenController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          title: const Text('Submit Feedback / Report Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Feedback Category'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: _typeOptions.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _screenController,
                  decoration: const InputDecoration(labelText: 'Screen / Page Location'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Report Details Description',
                    hintText: 'Please describe the bug details, incorrect scheme parameters, or suggestions...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final details = _detailsController.text.trim();
                      if (details.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please describe details before submitting.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);
                      
                      final success = await ref.read(feedbackProvider).submitFeedback(
                            screen: _screenController.text.trim(),
                            type: _selectedType,
                            details: details,
                            targetId: widget.targetId,
                          );

                      setState(() => _isSubmitting = false);
                      
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Thank you! Your feedback has been recorded.'
                                : 'Failed to submit feedback. Try again later.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
