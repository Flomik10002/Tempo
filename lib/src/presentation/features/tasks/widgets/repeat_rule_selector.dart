import 'package:flutter/material.dart';
import 'package:tempo/src/domain/entities/repeat_rule.dart';

class RepeatRuleSelector extends StatelessWidget {
  final RepeatRule? value;
  final ValueChanged<RepeatRule?> onChanged;

  const RepeatRuleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Repeat',
        prefixIcon: Icon(Icons.repeat),
      ),
      value: _getPresetKey(value),
      items: const [
        DropdownMenuItem(value: 'none', child: Text('No Repeat')),
        DropdownMenuItem(value: 'daily', child: Text('Every Day')),
        DropdownMenuItem(value: 'weekly', child: Text('Every Week')),
        DropdownMenuItem(value: 'workdays', child: Text('Every Workday')),
        DropdownMenuItem(value: 'custom', child: Text('Custom... (Not implemented)')),
      ],
      onChanged: (key) {
        if (key == null) return;
        
        switch (key) {
          case 'none':
            onChanged(null);
            break;
          case 'daily':
            onChanged(const FixedScheduleRepeat({1, 2, 3, 4, 5, 6, 7}));
            break;
          case 'weekly':
            // Текущий день недели
            final now = DateTime.now();
            onChanged(FixedScheduleRepeat({now.weekday}));
            break;
          case 'workdays':
            onChanged(const FixedScheduleRepeat({1, 2, 3, 4, 5}));
            break;
          case 'custom':
            // TODO: Open custom dialog
            break;
        }
      },
    );
  }

  String _getPresetKey(RepeatRule? rule) {
    if (rule == null) return 'none';
    
    if (rule is FixedScheduleRepeat) {
      if (rule.weekdays.length == 7) return 'daily';
      if (rule.weekdays.length == 5 && 
          rule.weekdays.containsAll({1, 2, 3, 4, 5})) return 'workdays';
      if (rule.weekdays.length == 1) return 'weekly';
    }
    
    return 'custom';
  }
}
