import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, BoxShadow; 

class TempoDesign {
  static const Color background = Color(0xFFF2F4F7);
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAFAFA), 
    ],
  );
  
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      offset: Offset(0, 10),
      blurRadius: 20,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.8),
      offset: Offset(-5, -5),
      blurRadius: 10,
    ),
  ];
}

class TempoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double width;
  
  const TempoCard({
    super.key, 
    required this.child, 
    this.padding = const EdgeInsets.all(20),
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: TempoDesign.glassGradient,
        boxShadow: TempoDesign.softShadow,
      ),
      child: child,
    );
  }
}

class TempoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLarge;

  const TempoButton({
    super.key, 
    required this.child, 
    this.onPressed,
    this.isLarge = false,
  });

  @override
  State<TempoButton> createState() => _TempoButtonState();
}

class _TempoButtonState extends State<TempoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.isLarge ? 70 : 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.isLarge ? 25 : 16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF0F0F3),
              ],
            ),
            boxShadow: _isPressed 
              ? [] 
              : const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  offset: Offset(0, 8),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
              ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class TempoActivityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? dotColor;

  const TempoActivityChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
     return GestureDetector(
       onTap: onTap,
       child: Container(
         margin: const EdgeInsets.symmetric(horizontal: 4),
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         decoration: BoxDecoration(
           color: isSelected ? const Color(0xFFF0F0F3) : Colors.transparent, 
           borderRadius: BorderRadius.circular(20),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             if (dotColor != null) ...[
               Container(
                 width: 8,
                 height: 8,
                 decoration: BoxDecoration(
                   color: dotColor,
                   shape: BoxShape.circle,
                 ),
               ),
               const SizedBox(width: 8),
             ],
             Text(
               label,
               style: TextStyle(
                 fontSize: 15,
                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                 color: isSelected ? CupertinoColors.black : CupertinoColors.systemGrey,
               ),
             ),
           ],
         ),
       ),
     );
  }
}

class TempoBadge extends StatelessWidget {
  final String text;
  final Color color;

  const TempoBadge({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
