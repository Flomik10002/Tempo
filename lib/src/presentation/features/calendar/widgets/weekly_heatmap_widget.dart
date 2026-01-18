import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // Fallback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tempo/src/presentation/features/calendar/providers/calendar_view_state.dart';
import 'package:tempo/src/presentation/features/calendar/providers/weekly_stats_provider.dart';

class WeeklyHeatmapWidget extends ConsumerWidget {
  const WeeklyHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final statsAsync = ref.watch(weeklyActivityStatsProvider(selectedDate));
    final weekStart = ref.watch(weekStartProvider(selectedDate));
    
    return statsAsync.when(
      data: (stats) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
             color: CupertinoDynamicColor.resolve(CupertinoColors.systemGroupedBackground, context),
             // border?
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayIndex = index + 1; // 1=Mon
              final date = weekStart.add(Duration(days: index));
              final isSelected = date.year == selectedDate.year && 
                                 date.month == selectedDate.month && 
                                 date.day == selectedDate.day;
              final isToday = _isToday(date);
              
              final duration = stats[dayIndex] ?? Duration.zero;
              final hours = duration.inMinutes / 60.0;
              
              // Calculate intensity: 0..1 (max 8 hours)
              final intensity = (hours / 8.0).clamp(0.0, 1.0);
              
              return GestureDetector(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = date;
                },
                child: Column(
                  children: [
                    Text(
                      DateFormat.E().format(date)[0], // M, T, W...
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected 
                            ? CupertinoColors.activeBlue 
                            : CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected && intensity == 0 
                            ? CupertinoColors.activeBlue.withOpacity(0.2) // Selected empty
                            : CupertinoColors.activeBlue.withOpacity(
                                intensity == 0 ? 0.05 : 0.2 + (intensity * 0.8)
                              ),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday 
                            ? Border.all(color: CupertinoColors.activeBlue, width: 2) 
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: intensity > 0 
                          ? Text(
                              duration.inHours > 0 ? '${duration.inHours}' : '',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.black, // Depending on opacity...
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
      loading: () => const SizedBox(height: 60, child: Center(child: CupertinoActivityIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

extension CupertinoColorsResolver on CupertinoColors {
   static Color customColor(BuildContext context, {required Color color}) {
     return CupertinoDynamicColor.resolve(color, context);
   }
}
