import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/use_case_providers.dart';
import 'package:tempo/src/domain/entities/activity_type.dart';

class ActivityEditorDialog extends ConsumerStatefulWidget {
  final ActivityType? activityToEdit;

  const ActivityEditorDialog({super.key, this.activityToEdit});

  @override
  ConsumerState<ActivityEditorDialog> createState() => _ActivityEditorDialogState();
}

class _ActivityEditorDialogState extends ConsumerState<ActivityEditorDialog> {
  late TextEditingController _nameController;
  late String _selectedColor;

  static const List<String> _colors = [
    '#007AFF', // Blue
    '#AF52DE', // Purple
    '#FF9500', // Orange
    '#FF3B30', // Red
    '#34C759', // Green
    '#5AC8FA', // Teal
    '#FFCC00', // Yellow
    '#5856D6', // Indigo
    '#8E8E93', // Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activityToEdit?.name ?? '');
    _selectedColor = widget.activityToEdit?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return; // Show error?

    if (widget.activityToEdit != null) {
      final updated = widget.activityToEdit!.copyWith(
        name: name,
        color: _selectedColor,
      );
      ref.read(updateActivityTypeUseCaseProvider).call(updated);
    } else {
      ref.read(createActivityTypeUseCaseProvider).call(name, _selectedColor);
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  widget.activityToEdit != null ? 'Edit Activity' : 'New Activity',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                ),
                CupertinoButton(
                  onPressed: _nameController.text.isNotEmpty ? _save : null,
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Name Input
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'Activity Name',
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemBackground, // DynamicColor
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onChanged: (val) => setState(() {}),
                  autofocus: true,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _colors.map((colorHex) {
                    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                    final isSelected = _selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? Border.all(color: CupertinoColors.label, width: 3) // Dynamic border color
                              : null,
                        ),
                        child: isSelected 
                            ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
