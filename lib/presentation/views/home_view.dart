import 'dart:ui';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/app_container.dart'; // Наш новый контейнер

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider).value;
    final duration = ref.watch(currentDurationProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);

    // Получаем правильные цвета текста из темы
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabelColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Gap(20),
            // Основной таймер
            AppContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Session', style: TextStyle(color: secondaryLabelColor)),
                      if (activeSession != null)
                        const Icon(CupertinoIcons.recordingtape, color: CupertinoColors.systemRed)
                    ],
                  ),
                  const Gap(10),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: labelColor,
                    ),
                  ),
                  const Gap(20),
                  if (activeSession != null)
                    SizedBox(
                      width: double.infinity,
                      child: AdaptiveButton(
                         // Flutter-кнопка стабильнее
                        onPressed: () => ref.read(appControllerProvider).toggleSession(activeSession.activityId),
                        label: 'Stop',
                        style: AdaptiveButtonStyle.filled,
                        color: CupertinoColors.systemRed,
                      ),
                    )
                  else
                    Text('Tap an activity to start', style: TextStyle(color: CupertinoTheme.of(context).primaryColor)),
                ],
              ),
            ),
            const Gap(30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: labelColor)),
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
                  error: (e, s) => Text('$e', style: TextStyle(color: labelColor)),
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

    return AdaptiveButton(
       // ВАЖНО: Используем Flutter-кнопки в списках, чтобы не лагало
      onPressed: () => ref.read(appControllerProvider).toggleSession(activity.id),
      label: activity.name,
      style: isActive ? AdaptiveButtonStyle.filled : AdaptiveButtonStyle.tinted,
      color: isActive ? activityColor : CupertinoColors.systemGrey5.resolveFrom(context),
      textColor: isActive ? CupertinoColors.white : activityColor,
    );
  }
}

class ActivitiesManagerPage extends ConsumerWidget {
  const ActivitiesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final labelColor = CupertinoColors.label.resolveFrom(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Manage Activities'),
        // Обычная кнопка вместо AdaptiveButton, чтобы не конфликтовала с навигатором
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showEditor(context, ref, null),
        ),
      ),
      child: SafeArea(
        child: activitiesAsync.when(
          data: (activities) {
            if (activities.isEmpty) return Center(child: Text('No activities', style: TextStyle(color: labelColor)));
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
                    decoration: BoxDecoration(color: CupertinoColors.destructiveRed, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(CupertinoIcons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => ref.read(appControllerProvider).deleteActivity(act.id),
                  child: AppContainer( // Используем легкий контейнер
                    onTap: () => _showEditor(context, ref, act),
                    child: Row(
                      children: [
                        Container(width: 16, height: 16, decoration: BoxDecoration(color: Color(int.parse(act.color)), shape: BoxShape.circle)),
                        const Gap(12),
                        Expanded(child: Text(act.name, style: TextStyle(color: labelColor, fontSize: 17))),
                        Icon(CupertinoIcons.pencil, size: 18, color: CupertinoColors.systemGrey.resolveFrom(context)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e,s) => Center(child: Text('$e', style: TextStyle(color: labelColor))),
        ),
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, Activity? activity) {
    final nameCtrl = TextEditingController(text: activity?.name ?? '');
    String selectedColor = activity?.color ?? '0xFF007AFF';
    final colors = ['0xFF007AFF', '0xFFFF2D55', '0xFF34C759', '0xFFFF9500', '0xFFAF52DE', '0xFF5856D6', '0xFF8E8E93', '0xFF000000'];
    final labelColor = CupertinoColors.label.resolveFrom(context);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Material( // Material нужен для обработки цветов
          color: Colors.transparent,
          child: CupertinoAlertDialog(
            title: Text(activity == null ? 'New Activity' : 'Edit Activity'),
            content: Column(
              children: [
                const Gap(16),
                CupertinoTextField(controller: nameCtrl, placeholder: 'Name'),
                const Gap(16),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: colors.map((c) => GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c)),
                        shape: BoxShape.circle,
                        border: selectedColor == c ? Border.all(color: labelColor, width: 3) : null,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    if (activity == null) {
                      ref.read(appControllerProvider).addActivity(nameCtrl.text, selectedColor);
                    } else {
                      ref.read(appControllerProvider).updateActivity(activity.copyWith(name: nameCtrl.text, color: selectedColor));
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}