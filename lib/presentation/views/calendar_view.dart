import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:tempo/logic.dart';

class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(sessionsForDateProvider(selectedDate));

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                AdaptiveButton(
                  style: AdaptiveButtonStyle.plain,
                  label: "Today",
                  onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
                ),
                const Spacer(),
                Text(
                    DateFormat.yMMMMd().format(selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const Spacer(),
                AdaptiveButton.icon(
                  icon: Icons.add,
                  style: AdaptiveButtonStyle.plain,
                  onPressed: () => _addManualLog(context, ref, selectedDate),
                ),
              ],
            ),
          ),

          // Days Ribbon
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 30,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (ctx, index) {
                  final date = DateTime.now().subtract(Duration(days: index));
                  final isSelected = isSameDay(date, selectedDate);
                  return GestureDetector(
                    onTap: () => ref.read(selectedDateProvider.notifier).state = date,
                    child: Container(
                      width: 50, margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat.E().format(date), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey)),
                          Text(date.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),

          // Timeline
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: SizedBox(
                height: 24 * 60.0,
                child: Stack(
                  children: [
                    // Grid
                    for (int i = 0; i < 24; i++)
                      Positioned(
                        top: i * 60.0, left: 0, right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2)))),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, top: 5),
                            child: Text('${i.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ),
                      ),

                    // Tap Area
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: (details) => _onTapEmpty(context, ref, details.localPosition.dy, selectedDate),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Segments
                    sessionsAsync.when(
                      data: (items) => Stack(
                        children: items.map((item) {
                          final top = _calculateTop(item.session.startTime);
                          final height = _calculateHeight(item.session.startTime, item.session.endTime);
                          final color = Color(int.parse(item.activity.color));

                          return Positioned(
                            top: top, left: 60, right: 10, height: height,
                            child: AdaptivePopupMenuButton.widget(
                              items: [
                                const AdaptivePopupMenuItem(label: 'Edit', value: 'edit', icon: Icons.edit),
                                const AdaptivePopupMenuItem(label: 'Delete', value: 'delete', icon: Icons.delete),
                              ],
                              onSelected: (idx, entry) {
                                if (entry.value == 'delete') {
                                  ref.read(appControllerProvider).deleteSession(item.session.id);
                                } else if (entry.value == 'edit') {
                                  _editSegment(context, ref, item);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Text(item.activity.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      loading: () => const SizedBox(),
                      error: (e,s) => const SizedBox(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers... (addManualLog, editSegment, calculateTop, calculateHeight, same as before but use AdaptiveDatePicker)

  double _calculateTop(DateTime start) => (start.hour * 60.0) + start.minute;
  double _calculateHeight(DateTime start, DateTime? end) {
    final e = end ?? DateTime.now();
    final diff = e.difference(start).inMinutes;
    return diff.toDouble().clamp(20.0, 1440.0);
  }

  void _onTapEmpty(BuildContext context, WidgetRef ref, double dy, DateTime date) {
    final hour = (dy / 60).floor();
    if(hour >= 24) return;
    final tapTime = DateTime(date.year, date.month, date.day, hour);
    _showAddDialog(context, ref, tapTime);
  }

  void _addManualLog(BuildContext context, WidgetRef ref, DateTime date) {
    final now = DateTime.now();
    final tapTime = DateTime(date.year, date.month, date.day, now.hour, now.minute);
    _showAddDialog(context, ref, tapTime);
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, DateTime start) {
    final activitiesAsync = ref.read(activitiesStreamProvider);
    activitiesAsync.whenData((activities) {
      if(activities.isEmpty) return;

      showCupertinoModalPopup(
          context: context,
          builder: (_) => CupertinoActionSheet(
            title: Text('Log Activity at ${DateFormat('HH:mm').format(start)}'),
            actions: activities.map((a) => CupertinoActionSheetAction(
              onPressed: () {
                ref.read(appControllerProvider).addSegment(start, start.add(const Duration(hours: 1)), a.id);
                Navigator.pop(context);
              },
              child: Text(a.name, style: TextStyle(color: Color(int.parse(a.color)))),
            )).toList(),
            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          )
      );
    });
  }

  void _editSegment(BuildContext context, WidgetRef ref, SessionWithActivity item) {
    DateTime start = item.session.startTime;
    DateTime end = item.session.endTime ?? DateTime.now();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 350,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text("Edit Time", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Gap(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Start'),
                  AdaptiveButton(label: DateFormat('HH:mm').format(start), onPressed: () async {
                    final t = await AdaptiveTimePicker.show(context: context, initialTime: TimeOfDay.fromDateTime(start));
                    if(t!=null) setState(() => start = DateTime(start.year, start.month, start.day, t.hour, t.minute));
                  }),
                ],
              ),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('End'),
                  AdaptiveButton(label: DateFormat('HH:mm').format(end), onPressed: () async {
                    final t = await AdaptiveTimePicker.show(context: context, initialTime: TimeOfDay.fromDateTime(end));
                    if(t!=null) setState(() => end = DateTime(end.year, end.month, end.day, t.hour, t.minute));
                  }),
                ],
              ),
              const Spacer(),
              AdaptiveButton(
                  label: 'Save Changes',
                  onPressed: () {
                    ref.read(appControllerProvider).updateSegmentTime(item.session.id, start, end);
                    Navigator.pop(ctx);
                  }
              )
            ],
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}