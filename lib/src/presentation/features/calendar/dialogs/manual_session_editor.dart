import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // For debugging/fallback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tempo/src/core/di/parts/use_case_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/entities/conflict_resolution.dart';
import 'package:tempo/src/presentation/features/home/providers/activity_types_provider.dart';

class ManualSessionEditor extends ConsumerStatefulWidget {
  final DateTime initialDate;

  const ManualSessionEditor({super.key, required this.initialDate});

  @override
  ConsumerState<ManualSessionEditor> createState() => _ManualSessionEditorState();
}

class _ManualSessionEditorState extends ConsumerState<ManualSessionEditor> {
  ActivityType? _selectedActivityType;
  late DateTime _startAt;
  late DateTime _endAt;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    // Default start: 9:00 AM on selected day
    final date = widget.initialDate;
    _startAt = DateTime(date.year, date.month, date.day, 9, 0);
    _endAt = _startAt.add(const Duration(hours: 1));
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_selectedActivityType == null) return;
    
    // Check constraints
    if (_endAt.isBefore(_startAt)) {
      // Show error
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Invalid Time'),
          content: const Text('End time must be after start time.'),
          actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
        ),
      );
      return;
    }

    final addSessionUseCase = ref.read(addManualSessionUseCaseProvider);
    
    final result = await addSessionUseCase.call(
      activityTypeId: _selectedActivityType!.id,
      startAt: _startAt,
      endAt: _endAt,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (result.isSuccess) {
      Navigator.of(context).pop();
    } else {
      // Conflicts
      _showConflictDialog(result.conflicts);
    }
  }
  
  void _showConflictDialog(List<SessionConflict> conflicts) {
    // Simplified conflict resolution for MVP: default to Trim
    // In full version, show options
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Conflict Detected'),
        content: Text('This session overlaps with ${conflicts.length} existing session(s). Adjust automatically?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
               // TODO: Call resolve conflict
               Navigator.pop(context);
               Navigator.pop(context); // Close editor
            },
            child: const Text('Overall (Trim/Split)'),
          ),
        ],
      ),
    );
  }

  void _showActivityPicker(List<ActivityType> types) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 CupertinoButton(
                   child: const Text('Done'),
                   onPressed: () => Navigator.pop(context),
                 ),
               ],
             ),
             Expanded(
               child: CupertinoPicker(
                 itemExtent: 32,
                 onSelectedItemChanged: (index) {
                   setState(() {
                     _selectedActivityType = types[index];
                   });
                 },
                 children: types.map((t) => Text(t.name)).toList(),
               ),
             ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activityTypesAsync = ref.watch(activityTypesProvider);
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('New Session'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectedActivityType == null ? null : _save,
          child: const Text('Add'),
        ),
      ),
      child: SafeArea(
        child: activityTypesAsync.when(
          data: (types) {
             if (_selectedActivityType == null && types.isNotEmpty) {
               // Auto-select first in next frame or here? 
               // Better avoid setState in build. Initialized with null is fine.
             }
             
             return ListView(
               children: [
                 CupertinoFormSection.insetGrouped(
                   header: const Text('Activity'),
                   children: [
                     CupertinoFormRow(
                       prefix: const Text('Type'),
                       child: CupertinoButton(
                         padding: EdgeInsets.zero,
                         onPressed: () => _showActivityPicker(types),
                         child: Text(
                           _selectedActivityType?.name ?? 'Select Activity',
                           style: TextStyle(
                             color: _selectedActivityType == null 
                               ? CupertinoColors.placeholderText 
                               : CupertinoColors.label,
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
                 
                 CupertinoFormSection.insetGrouped(
                   header: const Text('Time'),
                   children: [
                     _buildDatePickerRow('Start', _startAt, (date) => setState(() => _startAt = date)),
                     _buildDatePickerRow('End', _endAt, (date) => setState(() => _endAt = date)),
                   ],
                 ),
                 
                 CupertinoFormSection.insetGrouped(
                   header: const Text('Note'),
                   children: [
                     CupertinoTextFormFieldRow(
                       controller: _noteController,
                       placeholder: 'Add a note',
                       maxLines: 3,
                     ),
                   ],
                 ),
               ],
             );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
  
  Widget _buildDatePickerRow(String label, DateTime value, ValueChanged<DateTime> onChanged) {
    return CupertinoFormRow(
      prefix: Text(label),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
           showCupertinoModalPopup(
             context: context,
             builder: (context) => Container(
               height: 250,
               color: CupertinoColors.systemBackground.resolveFrom(context),
               child: Column(
                 children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          child: const Text('Done'),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.dateAndTime,
                        initialDateTime: value,
                        onDateTimeChanged: onChanged,
                        use24hFormat: true,
                      ),
                    ),
                 ],
               ),
             ),
           );
        },
        child: Text(
          DateFormat('MMM d, HH:mm').format(value),
          style: const TextStyle(color: CupertinoColors.label),
        ),
      ),
    );
  }
}
