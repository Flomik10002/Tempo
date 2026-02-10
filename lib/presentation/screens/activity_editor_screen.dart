import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ActivityEditorScreen extends ConsumerStatefulWidget {
  final Activity? activity;

  const ActivityEditorScreen({super.key, this.activity});

  @override
  ConsumerState<ActivityEditorScreen> createState() => _ActivityEditorScreenState();
}

class _ActivityEditorScreenState extends ConsumerState<ActivityEditorScreen> {
  late TextEditingController _nameCtrl;
  late Color _selectedColor;

  // Предустановленные цвета для быстрого выбора
  final List<Color> _presetColors = [
    const Color(0xFF007AFF),
    const Color(0xFFFF2D55),
    const Color(0xFF34C759),
    const Color(0xFFFF9500),
    const Color(0xFFAF52DE),
    const Color(0xFF5856D6),
    const Color(0xFF8E8E93),
    const Color(0xFF000000),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.activity?.name ?? '');
    // Парсим цвет из строки формата '0xFFRRGGBB'
    _selectedColor = widget.activity != null
        ? Color(int.parse(widget.activity!.color))
        : const Color(0xFF007AFF);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // Проверяем, является ли выбранный цвет предустановленным
  bool _isPresetColor(Color color) {
    return _presetColors.any((c) => c.value == color.value);
  }

  // Открываем color picker
  void _showColorPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        Color pickerColor = _selectedColor;
        
        return Container(
          height: 500,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    Text(
                      'Choose Color',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() => _selectedColor = pickerColor);
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              // Color Picker
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (Color color) {
                      pickerColor = color;
                    },
                    pickerAreaHeightPercent: 0.8,
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: const [],
                    pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              // Предустановленные цвета
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Предустановленные цвета
                  ..._presetColors.map((color) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor.value == color.value
                            ? Border.all(color: labelColor, width: 3)
                            : Border.all(color: CupertinoColors.separator.resolveFrom(context), width: 1),
                      ),
                    ),
                  )),
                  // Кнопка для кастомного цвета
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.color_filter,
                        color: labelColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              // Показываем выбранный кастомный цвет, если он не предустановленный
              if (!_isPresetColor(_selectedColor)) ...[
                const Gap(16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: labelColor, width: 2),
                        ),
                      ),
                      const Gap(12),
                      Text(
                        'Custom Color',
                        style: TextStyle(
                          fontSize: 15,
                          color: labelColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    
    // Конвертируем цвет обратно в строковый формат '0xFFRRGGBB' для совместимости с БД
    final colorString = '0x${_selectedColor.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
    
    if (widget.activity == null) {
      ref.read(appControllerProvider).addActivity(_nameCtrl.text.trim(), colorString);
    } else {
      ref.read(appControllerProvider).updateActivity(
          widget.activity!.copyWith(name: _nameCtrl.text.trim(), color: colorString)
      );
    }
    Navigator.pop(context);
  }
}