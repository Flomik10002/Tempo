import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

class NativeGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const NativeGlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveBlurView(
      borderRadius: BorderRadius.circular(20),
      blurStyle: BlurStyle.systemThickMaterial,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}