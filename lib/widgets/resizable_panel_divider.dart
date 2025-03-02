import 'package:flutter/material.dart';

class ResizablePanelDivider extends StatefulWidget {
  final Function(double) onDrag;
  final Color? color;
  final double width;
  final VoidCallback? onDoubleTap;
  
  const ResizablePanelDivider({
    Key? key,
    required this.onDrag,
    this.color,
    this.width = 8.0,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  State<ResizablePanelDivider> createState() => _ResizablePanelDividerState();
}

class _ResizablePanelDividerState extends State<ResizablePanelDivider> {
  bool _isDragging = false;
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dragColor = isDark 
        ? const Color(0xFFEEAA00) // 黄色系，无蓝色
        : Theme.of(context).colorScheme.primary;
    
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onHorizontalDragUpdate: (details) {
          widget.onDrag(details.delta.dx);
        },
        onHorizontalDragEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onDoubleTap: widget.onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: _isDragging
                ? dragColor.withOpacity(0.5)
                : _isHovering
                    ? Theme.of(context).dividerColor.withOpacity(0.5)
                    : widget.color ?? Theme.of(context).dividerColor.withOpacity(0.3),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: _isDragging ? 3 : 2,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? dragColor
                        : _isHovering 
                            ? Theme.of(context).dividerColor.withOpacity(0.8)
                            : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: _isDragging ? 3 : 2,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? dragColor
                        : _isHovering 
                            ? Theme.of(context).dividerColor.withOpacity(0.8)
                            : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 