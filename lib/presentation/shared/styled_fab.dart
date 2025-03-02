import 'package:flutter/material.dart';

class StyledFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const StyledFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      elevation: 4,
      highlightElevation: 8,
      backgroundColor: backgroundColor ?? colorScheme.primary,
      foregroundColor: foregroundColor ?? colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Icon(icon, size: 24.0),
    );
  }
}
