import 'dart:ui';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/native_glass_container.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider).value;
    final duration = ref.watch(currentDurationProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Gap(20),
            SizedBox(
              height: 220,
              child: NativeGlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Session', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        if (activeSession != null)
                          const CNIcon(symbol: CNSymbol('record.circle', color: CupertinoColors.systemRed))
                      ],
                    ),
                    const Gap(10),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const Gap(20),
                    if (activeSession != null)
                      SizedBox(
                        width: double.infinity,
                        child: AdaptiveButton(
                          onPressed: () => ref.read(appControllerProvider).toggleSession(activeSession.activityId),
                          label: 'Stop',
                          style: AdaptiveButtonStyle.filled,
                          color: CupertinoColors.systemRed,
                        ),
                      )
                    else
                      Text('Tap an activity to start', style: TextStyle(color: CupertinoColors.activeBlue.resolveFrom(context))),
                  ],
                ),
              ),
            ),
            const Gap(30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activities', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
                // ИСПРАВЛЕНИЕ ЗДЕСЬ: Используем AdaptiveButton.icon
                AdaptiveButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(builder: (_) => const ActivitiesManagerPage()),
                  ),
                  style: AdaptiveButtonStyle.plain,
                  icon: CupertinoIcons.gear,
                ),
              ],
            ),
            const Gap(10),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: activitiesAsync.when(
                  data: (activities) => Wrap(
                    spacing: 12, runSpacing: 12,
                    children: [
                      ...activities.map((act) => _ActivityChip(activity: act, isActive: activeSession?.activityId == act.id)),
                    ],
                  ),
                  loading: () => const CupertinoActivityIndicator(),
                  error: (e, s) => Text('$e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class _ActivityChip extends ConsumerWidget {
  final Activity activity;
  final bool isActive;
  const _ActivityChip({required this.activity, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveButton(
      onPressed: () => ref.read(appControllerProvider).toggleSession(activity.id),
      label: activity.name,
      style: isActive ? AdaptiveButtonStyle.filled : AdaptiveButtonStyle.tinted,
      color: isActive ? CupertinoTheme.of(context).primaryColor : CupertinoColors.systemGrey5.resolveFrom(context),
      textColor: isActive ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
    );
  }
}

// --- ACTIVITIES MANAGER PAGE ---
class ActivitiesManagerPage extends ConsumerWidget {
  const ActivitiesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Manage Activities'),
        trailing: AdaptiveButton.icon( // ИСПРАВЛЕНИЕ ЗДЕСЬ
          style: AdaptiveButtonStyle.plain,
          icon: CupertinoIcons.add,
          onPressed: () => _showEditor(context, ref, null),
        ),
      ),
      child: SafeArea(
        child: activitiesAsync.when(
          data: (activities) {
            if (activities.isEmpty) return const Center(child: Text('No activities'));
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: activities.length,
              separatorBuilder: (_,__) => const Gap(12),
              itemBuilder: (ctx, index) {
                final act = activities[index];
                return Dismissible(
                  key: Key('act_${act.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: CupertinoColors.destructiveRed, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(CupertinoIcons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => ref.read(appControllerProvider).deleteActivity(act.id),
                  child: AdaptiveListTile(
                    onTap: () => _showEditor(context, ref, act),
                    title: Text(act.name),
                    leading: Container(width: 16, height: 16, decoration: BoxDecoration(color: Color(int.parse(act.color)), shape: BoxShape.circle)),
                    trailing: const Icon(CupertinoIcons.pencil, size: 16),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e,s) => Center(child: Text('$e')),
        ),
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, Activity? activity) {
    final nameCtrl = TextEditingController(text: activity?.name ?? '');
    String selectedColor = activity?.color ?? '0xFF007AFF';
    final colors = ['0xFF007AFF', '0xFFFF2D55', '0xFF34C759', '0xFFFF9500', '0xFFAF52DE', '0xFF5856D6', '0xFF8E8E93', '0xFF000000'];

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CupertinoColors.label.resolveFrom(context))),
                    const Gap(20),
                    CupertinoTextField(controller: nameCtrl, placeholder: 'Name'),
                    const Gap(20),
                    Text('Color', style: TextStyle(color: CupertinoColors.systemGrey.resolveFrom(context))),
                    const Gap(10),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: colors.map((c) => GestureDetector(
                        onTap: () => setState(() => selectedColor = c),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Color(int.parse(c)),
                            shape: BoxShape.circle,
                            border: selectedColor == c ? Border.all(color: CupertinoColors.label.resolveFrom(context), width: 3) : null,
                          ),
                        ),
                      )).toList(),
                    ),
                    const Gap(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AdaptiveButton(label: 'Cancel', style: AdaptiveButtonStyle.plain, onPressed: () => Navigator.pop(ctx)),
                        const Gap(8),
                        AdaptiveButton(label: 'Save', onPressed: () {
                          if (nameCtrl.text.isNotEmpty) {
                            if (activity == null) {
                              ref.read(appControllerProvider).addActivity(nameCtrl.text, selectedColor);
                            } else {
                              ref.read(appControllerProvider).updateActivity(activity.copyWith(name: nameCtrl.text, color: selectedColor));
                            }
                            Navigator.pop(ctx);
                          }
                        }),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}