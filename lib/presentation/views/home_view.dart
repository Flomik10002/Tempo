import 'dart:ui';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Material, Dismissible, DismissDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/app_container.dart';
import 'package:tempo/presentation/screens/activity_editor_screen.dart'; // Новый экран

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider).value;
    final duration = ref.watch(currentDurationProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabelColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Gap(20),
            AppContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Session', style: TextStyle(color: secondaryLabelColor, fontWeight: FontWeight.w500)),
                      if (activeSession != null)
                        const Icon(CupertinoIcons.bolt_fill, color: CupertinoColors.systemYellow)
                    ],
                  ),
                  const Gap(10),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: labelColor,
                    ),
                  ),
                  const Gap(24),
                  if (activeSession != null)
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: () => ref.read(appControllerProvider).toggleSession(activeSession.activityId),
                        child: const Text('Stop Recording', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    Text('Choose activity to start', style: TextStyle(color: CupertinoTheme.of(context).primaryColor, fontSize: 15)),
                ],
              ),
            ),
            const Gap(40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activities', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: labelColor)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(builder: (_) => const ActivitiesManagerPage()),
                  ),
                  child: const Icon(CupertinoIcons.settings, size: 24),
                ),
              ],
            ),
            const Gap(16),
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
    final activityColor = Color(int.parse(activity.color));

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => ref.read(appControllerProvider).toggleSession(activity.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          // Если активна - красим в цвет активности, если нет - в прозрачно-серый
          color: isActive ? activityColor : CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : activityColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          activity.name,
          style: TextStyle(
              color: isActive ? Colors.white : activityColor,
              fontWeight: FontWeight.w600,
              fontSize: 16
          ),
        ),
      ),
    );
  }
}

// --- ACTIVITIES MANAGER PAGE ---
class ActivitiesManagerPage extends ConsumerWidget {
  const ActivitiesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final labelColor = CupertinoColors.label.resolveFrom(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Manage Activities'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const ActivityEditorScreen()),
          ),
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
                  key: Key('act_manage_${act.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: CupertinoColors.destructiveRed, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(CupertinoIcons.trash, color: Colors.white),
                  ),
                  onDismissed: (_) => ref.read(appControllerProvider).deleteActivity(act.id),
                  child: AppContainer(
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => ActivityEditorScreen(activity: act)),
                    ),
                    child: Row(
                      children: [
                        Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(color: Color(int.parse(act.color)), shape: BoxShape.circle)
                        ),
                        const Gap(16),
                        Expanded(child: Text(act.name, style: TextStyle(color: labelColor, fontSize: 18, fontWeight: FontWeight.w500))),
                        Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      ],
                    ),
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
}