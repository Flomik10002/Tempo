import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, Theme, Brightness, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/health_sync_service.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/app_container.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _isAuthorizingHealth = false;
  String? _healthStatus;

  Future<void> _authorizeAppleHealth() async {
    setState(() {
      _isAuthorizingHealth = true;
      _healthStatus = null;
    });

    final result =
        await ref.read(healthSyncServiceProvider).authorizeSleepWriteAccess();

    if (!mounted) return;
    setState(() {
      _isAuthorizingHealth = false;
      _healthStatus = result.message;
    });

    final isSuccess = result.status == HealthAuthorizationStatus.authorized;
    final dialogColor =
        isSuccess ? CupertinoColors.systemGreen : CupertinoColors.systemRed;

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          isSuccess ? 'Apple Health Connected' : 'Apple Health Not Connected',
        ),
        content: Text(result.message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: dialogColor.resolveFrom(context)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Определяем, включена ли темная тема РЕАЛЬНО (независимо от того, выбрано System или Dark)
    final isActuallyDark = Theme.of(context).brightness == Brightness.dark;

    final labelColor = CupertinoColors.label.resolveFrom(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: labelColor)),
            const Gap(30),
            AppContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dark Mode',
                      style: TextStyle(fontSize: 17, color: labelColor)),
                  AdaptiveSwitch(
                    value: isActuallyDark,
                    activeColor: CupertinoTheme.of(context).primaryColor,
                    onChanged: (val) {
                      // Сохраняем и применяем выбор
                      ref
                          .read(themeModeProvider.notifier)
                          .setTheme(val ? ThemeMode.dark : ThemeMode.light);
                    },
                  )
                ],
              ),
            ),
            const Gap(12),
            AppContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Apple Health',
                      style: TextStyle(fontSize: 17, color: labelColor)),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed:
                        _isAuthorizingHealth ? null : _authorizeAppleHealth,
                    child: _isAuthorizingHealth
                        ? const CupertinoActivityIndicator()
                        : const Text('Connect'),
                  ),
                ],
              ),
            ),
            if (_healthStatus != null) ...[
              const Gap(8),
              Text(
                _healthStatus!,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
            const Gap(20),
            const Center(
                child: Text("Tempo v1.0", style: TextStyle(color: Colors.grey)))
          ],
        ),
      ),
    );
  }
}
