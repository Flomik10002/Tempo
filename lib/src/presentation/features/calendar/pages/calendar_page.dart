import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/presentation/features/calendar/providers/calendar_view_state.dart';
import 'package:tempo/src/presentation/features/calendar/providers/session_list_provider.dart';
import 'package:tempo/src/presentation/features/calendar/widgets/day_timeline_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:tempo/src/presentation/features/calendar/dialogs/manual_session_editor.dart';
import 'package:tempo/src/presentation/features/calendar/widgets/weekly_heatmap_widget.dart';
import 'package:tempo/src/presentation/features/home/providers/activity_types_provider.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(sessionsForDayProvider(selectedDate));
    final activityTypesAsync = ref.watch(activityTypesProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: GestureDetector(
          onTap: () => _showDatePicker(context, ref, selectedDate),
          child: Text(DateFormat.yMMMMd().format(selectedDate)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
              child: const Icon(CupertinoIcons.today),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => ManualSessionEditor(initialDate: selectedDate),
                );
              },
              child: const Icon(CupertinoIcons.add),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const WeeklyHeatmapWidget(),
            Expanded(
              child: activityTypesAsync.when(
                data: (activityTypes) {
                   final activityTypeMap = {
                     for (var type in activityTypes) type.id: type
                   };
                   
                   return sessionsAsync.when(
                     data: (sessions) {
                       return DayTimelineWidget(
                         sessions: sessions,
                         activityTypeMap: activityTypeMap,
                       );
                     },
                     loading: () => const Center(child: CupertinoActivityIndicator()),
                     error: (err, stack) => Center(child: Text('Error: $err')),
                   );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context, WidgetRef ref, DateTime initialDate) {
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
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                onDateTimeChanged: (val) {
                  ref.read(selectedDateProvider.notifier).state = val;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
