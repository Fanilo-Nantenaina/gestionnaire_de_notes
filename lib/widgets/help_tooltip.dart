import 'package:flutter/material.dart';

class HelpTooltip extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const HelpTooltip({
    super.key,
    required this.message,
    this.icon = Icons.help_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        height: 1.4,
      ),
      child: Icon(
        icon,
        size: 20,
        color: color ?? Colors.grey[600],
      ),
    );
  }
}
