import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/native_glass_container.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Settings',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)
            ),
            const Gap(30),
            NativeGlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode', style: TextStyle(fontSize: 17)),
                  AdaptiveSwitch(
                    value: isDark,
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