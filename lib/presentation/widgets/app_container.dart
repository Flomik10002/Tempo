import 'package:flutter/cupertino.dart';

class AppContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Получаем цвета, которые сами меняются при смене темы
    final backgroundColor = CupertinoColors.secondarySystemBackground.resolveFrom(context);
    final borderColor = CupertinoColors.separator.resolveFrom(context);

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor, // В светлой теме - светло-серый, в темной - темно-серый
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }

    return container;
  }
}