import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';

class ActivityEditorScreen extends ConsumerStatefulWidget {
  final Activity? activity;

  const ActivityEditorScreen({super.key, this.activity});

  @override
  ConsumerState<ActivityEditorScreen> createState() => _ActivityEditorScreenState();
}

class _ActivityEditorScreenState extends ConsumerState<ActivityEditorScreen> {
  late TextEditingController _nameCtrl;
  late String _selectedColor;

  final List<String> _colors = [
    '0xFF007AFF', '0xFFFF2D55', '0xFF34C759', '0xFFFF9500',
    '0xFFAF52DE', '0xFF5856D6', '0xFF8E8E93', '0xFF000000'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.activity?.name ?? '');
    _selectedColor = widget.activity?.color ?? '0xFF007AFF';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activity != null;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final bgColor = CupertinoColors.secondarySystemBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(isEditing ? 'Edit Activity' : 'New Activity'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NAME', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryColor)),
              const Gap(8),
              CupertinoTextField(
                controller: _nameCtrl,
                placeholder: 'Activity Name',
                textCapitalization: TextCapitalization.words,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              ),
              const Gap(32),
              Text('COLOR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryColor)),
              const Gap(12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _colors.map((c) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c)),
                      shape: BoxShape.circle,
                      border: _selectedColor == c
                          ? Border.all(color: labelColor, width: 3)
                          : Border.all(color: CupertinoColors.separator.resolveFrom(context), width: 1),
                    ),
                  ),
                )).toList(),
              ),
              if (isEditing) ...[
                const Gap(60),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: CupertinoColors.destructiveRed,
                    onPressed: () {
                      ref.read(appControllerProvider).deleteActivity(widget.activity!.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete Activity', style: TextStyle(color: CupertinoColors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (widget.activity == null) {
      ref.read(appControllerProvider).addActivity(_nameCtrl.text.trim(), _selectedColor);
    } else {
      ref.read(appControllerProvider).updateActivity(
          widget.activity!.copyWith(name: _nameCtrl.text.trim(), color: _selectedColor)
      );
    }
    Navigator.pop(context);
  }
}