import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/app_container.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;
    final labelColor = CupertinoColors.label.resolveFrom(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Settings',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: labelColor)
            ),
            const Gap(30),
            AppContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dark Mode', style: TextStyle(fontSize: 17, color: labelColor)),
                  AdaptiveSwitch(
                    value: isDark,
                    activeColor: CupertinoTheme.of(context).primaryColor,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                    },
                  )
                ],
              ),
            ),
            const Gap(20),
            const Center(child: Text("Tempo v1.0", style: TextStyle(color: Colors.grey)))
          ],
        ),
      ),
    );
  }
}