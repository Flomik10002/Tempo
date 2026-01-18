import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_native/cupertino_native.dart';

import 'package:tempo/src/core/di/parts/use_case_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/presentation/core/theme/theme_provider.dart';
import 'package:tempo/src/presentation/core/widgets/tempo_design_system.dart';
import 'package:tempo/src/presentation/features/home/providers/activity_types_provider.dart';
import 'package:tempo/src/presentation/features/home/providers/current_session_provider.dart';
import 'package:tempo/src/presentation/features/calendar/providers/session_list_provider.dart';
import 'package:tempo/src/presentation/features/home/providers/selected_activity_provider.dart';
import 'package:tempo/src/presentation/features/home/dialogs/activity_editor_dialog.dart';
import 'package:tempo/src/presentation/features/home/pages/activities_management_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    
    final sessionsAsync = ref.watch(sessionsForDayProvider(today));
    final activityTypesAsync = ref.watch(activityTypesProvider);
    final currentSessionAsync = ref.watch(currentSessionProvider);
    final elapsedTimeAsync = ref.watch(sessionElapsedTimeProvider);
    final themeMode = ref.watch(themeProvider);

    return CupertinoPageScaffold(
      backgroundColor: TempoDesign.background,
      navigationBar: CupertinoNavigationBar(
         middle: const Text('Tempo'),
         trailing: CNPopupMenuButton(
            child: const Icon(CupertinoIcons.ellipsis_circle),
            items: [
              const CNPopupMenuItem(label: 'Add Activity', icon: CNSymbol('plus')),
              const CNPopupMenuItem(label: 'Manage Activities', icon: CNSymbol('list.bullet')),
              const CNPopupMenuDivider(),
              CNPopupMenuItem(
                label: themeMode == AppThemeMode.light ? 'Dark Mode' : 'Light Mode', 
                icon: CNSymbol(themeMode == AppThemeMode.light ? 'moon.fill' : 'sun.max.fill')
              ),
            ],
            onSelected: (index) {
               if (index == 0) {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => const ActivityEditorDialog(),
                  );
               } else if (index == 1) {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => const ActivitiesManagementPage(),
                  );
               } else if (index == 3) { // 0=Add, 1=Manage, 2=Divider, 3=Theme
                  ref.read(themeProvider.notifier).toggle();
               }
            },
         ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                currentSessionAsync.value != null 
                    ? 'Active Session' 
                    : 'No active session',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: TempoDesign.textSecondary,
                ),
              ),
              const SizedBox(height: 30),
              
              // Main Timer Card
              TempoCard(
                child: Column(
                  children: [
                    // Timer row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sessionsAsync.when(
                              data: (sessions) {
                                final total = sessions.fold(Duration.zero, (prev, s) {
                                  final dur = s.endAt?.difference(s.startAt) ?? Duration.zero;
                                  return prev + dur;
                                });
                                
                                return Text(
                                  'WH: ${_formatDuration(total)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: TempoDesign.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                              loading: () => const Text('WH: --:--', style: TextStyle(color: TempoDesign.textSecondary)),
                              error: (_, __) => const Text('WH: --:--', style: TextStyle(color: TempoDesign.textSecondary)),
                            ),
                            const SizedBox(height: 8),
                            // Progress bar placeholder
                            Container(
                              width: 100,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.6, // Placeholder
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5856D6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDuration(elapsedTimeAsync ?? Duration.zero),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: TempoDesign.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // History List
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: sessionsAsync.when(
                        data: (sessions) {
                          if (sessions.isEmpty) {
                            return const Center(child: Text('No sessions yet', style: TextStyle(color: TempoDesign.textSecondary)));
                          }
                          // Filter completed
                          final completed = sessions.where((s) => s.endAt != null).toList().reversed.toList();
                          
                          if (completed.isEmpty) {
                             return const Center(child: Text('No completed sessions', style: TextStyle(color: TempoDesign.textSecondary)));
                          }

                          return activityTypesAsync.when(
                             data: (types) {
                               final typeMap = {for (var t in types) t.id: t};
                               
                               return ListView.separated(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: completed.length > 3 ? 3 : completed.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final s = completed[index];
                                  final duration = s.endAt!.difference(s.startAt);
                                  final type = typeMap[s.activityTypeId];
                                  final name = type?.name ?? s.note ?? 'Activity';
                                  final colorHex = type?.color ?? '#007AFF';
                                  final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

                                  return _buildHistoryItem(
                                    name,
                                    _formatDuration(duration),
                                    color,
                                    true
                                  );
                                },
                              );
                             },
                             loading: () => const CupertinoActivityIndicator(),
                             error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                        loading: () => const CupertinoActivityIndicator(),
                        error: (_, __) => const Text('Error loading history'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Main Button
              TempoButton(
                isLarge: true,
                onPressed: () {
                   final session = currentSessionAsync.value;
                   if (session == null) {
                     _startSession(context, ref);
                   } else {
                     ref.read(stopSessionUseCaseProvider).call();
                   }
                },
                child: Text(
                  currentSessionAsync.value != null ? 'Stop' : 'Start',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: TempoDesign.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Activity Selector (Scrollable Segmented Control)
              SizedBox(
                 height: 40,
                 child: activityTypesAsync.when(
                    data: (types) {
                      if (types.isEmpty) return const SizedBox.shrink();
                      return _ActivitySelector(types: types);
                    },
                    loading: () => const CupertinoActivityIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                 ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String name, String time, Color color, bool isDone) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color, 
          ),
          child: const Icon(CupertinoIcons.checkmark, size: 10, color: CupertinoColors.white),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: TempoDesign.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            color: TempoDesign.textSecondary,
            fontFamily: 'Courier', 
          ),
        ),
        const SizedBox(width: 8),
        const Icon(CupertinoIcons.chevron_right, size: 14, color: TempoDesign.textSecondary),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMilliseconds == 0) return '00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
  
  void _startSession(BuildContext context, WidgetRef ref) {
     final selectedId = ref.read(selectedActivityIdProvider);
     if (selectedId != null) {
        ref.read(startSessionUseCaseProvider).call(selectedId);
     } else {
        // Fallback to first if not selected?
        final activityTypes = ref.read(activityTypesProvider).value;
        if (activityTypes != null && activityTypes.isNotEmpty) {
           ref.read(startSessionUseCaseProvider).call(activityTypes.first.id);
        }
     }
  }
}

class _ActivitySelector extends ConsumerStatefulWidget {
   final List<ActivityType> types;
   const _ActivitySelector({required this.types});
   
   @override
   ConsumerState<_ActivitySelector> createState() => _ActivitySelectorState();
}

class _ActivitySelectorState extends ConsumerState<_ActivitySelector> {
   String? _selectedId;

   @override
   void initState() {
     super.initState();
     if (widget.types.isNotEmpty) {
       _selectedId = widget.types.first.id;
        // Initialize global provider too?
        // Better to check if global is null, then set it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (ref.read(selectedActivityIdProvider) == null) {
              ref.read(selectedActivityIdProvider.notifier).state = widget.types.first.id;
              setState(() => _selectedId = widget.types.first.id);
           } else {
              setState(() => _selectedId = ref.read(selectedActivityIdProvider));
           }
        });
     }
   }

   @override
   Widget build(BuildContext context) {
      final map = <String, Widget>{};
      for (var t in widget.types) {
         map[t.id] = Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16),
           child: Text(t.name),
         );
      }

      return SingleChildScrollView(
         scrollDirection: Axis.horizontal,
         child: CupertinoSlidingSegmentedControl<String>(
            groupValue: _selectedId,
            children: map,
            onValueChanged: (val) {
               if (val != null) {
                 setState(() => _selectedId = val);
                 ref.read(selectedActivityIdProvider.notifier).state = val;
               }
            },
         ),
      );
   }
}
