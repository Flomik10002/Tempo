import 'dart:io';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'; // Только для AdaptiveTimePicker
import 'package:cupertino_native/cupertino_native.dart'; // Для иконок CNSymbol
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
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                    DateFormat.yMMMMd().format(selectedDate),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: labelColor)
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text("Today", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                  onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
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
                        color: isSelected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat.E().format(date), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : CupertinoColors.systemGrey)),
                          Text(date.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : labelColor)),
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
              padding: const EdgeInsets.only(bottom: 20),
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
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.5)))),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, top: 5),
                            child: Text('${i.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                          ),
                        ),
                      ),

                    // Tap Area
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) => _onTapEmpty(context, ref, details.localPosition.dy, selectedDate),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Segments
                    sessionsAsync.when(
                      data: (items) => Stack(
                        children: items.map((item) {
                          final layout = _calculateLayout(item.session.startTime, item.session.endTime, selectedDate);
                          final color = Color(int.parse(item.activity.color));

                          return Positioned(
                            top: layout.top,
                            left: 60,
                            right: 10,
                            height: layout.height,
                            child: GestureDetector(
                              onTap: () => _showEditMenu(context, ref, item),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Text(item.activity.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
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

  // Расчет позиции сегмента с учетом перехода через полночь
  ({double top, double height}) _calculateLayout(DateTime start, DateTime? end, DateTime selectedDate) {
    final effectiveEnd = end ?? DateTime.now();

    // Границы текущего дня
    final dayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Если событие вообще не попадает в этот день (например, началось и закончилось вчера, но запрос в БД вернул его по ошибке)
    if (effectiveEnd.isBefore(dayStart) || start.isAfter(dayEnd)) {
      return (top: -1000, height: 0); // Скрываем
    }

    // Обрезаем начало и конец по границам дня
    final visibleStart = start.isBefore(dayStart) ? dayStart : start;
    final visibleEnd = effectiveEnd.isAfter(dayEnd) ? dayEnd : effectiveEnd;

    final startMinutes = visibleStart.difference(dayStart).inMinutes;
    final durationMinutes = visibleEnd.difference(visibleStart).inMinutes;

    double top = startMinutes.toDouble();
    double height = durationMinutes.toDouble();

    if (height < 20) height = 20;

    return (top: top, height: height);
  }

  void _onTapEmpty(BuildContext context, WidgetRef ref, double dy, DateTime date) {
    final hour = (dy / 60).floor();
    if(hour >= 24) return;
    final tapTime = DateTime(date.year, date.month, date.day, hour);
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

  // Меню действий с сегментом (Нативное меню через модалку)
  void _showEditMenu(BuildContext context, WidgetRef ref, SessionWithActivity item) {
    showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          // Эмуляция нативного меню с иконками SF Symbols
          actions: [
            CupertinoActionSheetAction(
              onPressed: () { Navigator.pop(ctx); _editSegment(context, ref, item); },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Edit Time'),
                  const Gap(8),
                  // Используем CNIcon для нативного SF Symbol
                  const CNIcon(symbol: CNSymbol('clock', size: 18), color: CupertinoColors.activeBlue),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () { Navigator.pop(ctx); ref.read(appControllerProvider).deleteSession(item.session.id); },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Delete'),
                  const Gap(8),
                  const CNIcon(symbol: CNSymbol('trash', size: 18), color: CupertinoColors.destructiveRed),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        )
    );
  }

  void _editSegment(BuildContext context, WidgetRef ref, SessionWithActivity item) {
    DateTime start = item.session.startTime;
    DateTime end = item.session.endTime ?? DateTime.now();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Material(
          color: Colors.transparent,
          child: Container(
            height: 400,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text("Edit Session", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CupertinoColors.label.resolveFrom(context))),
                const Gap(20),
                _buildDateTimeRow(context, 'Start', start, (d) => setState(() => start = d)),
                const Gap(10),
                _buildDateTimeRow(context, 'End', end, (d) => setState(() => end = d)),
                const Spacer(),
                CupertinoButton.filled(
                    child: const Text('Save Changes'),
                    onPressed: () {
                      ref.read(appControllerProvider).updateSegmentTime(item.session.id, start, end);
                      Navigator.pop(ctx);
                    }
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(BuildContext context, String label, DateTime dt, Function(DateTime) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 17)),
        Row(
          children: [
            CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(DateFormat('MMM d').format(dt), style: const TextStyle(fontSize: 15)),
                onPressed: () async {
                  final date = await AdaptiveDatePicker.show(context: context, initialDate: dt);
                  if (date != null) {
                    onChanged(DateTime(date.year, date.month, date.day, dt.hour, dt.minute));
                  }
                }
            ),
            CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                        borderRadius: BorderRadius.circular(6)
                    ),
                    child: Text(DateFormat('HH:mm').format(dt), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
                ),
                onPressed: () async {
                  final t = await AdaptiveTimePicker.show(context: context, initialTime: TimeOfDay.fromDateTime(dt));
                  if (t != null) {
                    onChanged(DateTime(dt.year, dt.month, dt.day, t.hour, t.minute));
                  }
                }
            ),
          ],
        )
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}