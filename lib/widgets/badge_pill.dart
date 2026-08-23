import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class BadgePill extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const BadgePill({
    super.key,
    required this.text,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = color ?? AppTheme.accent;

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppFontSize.micro,
              color: AppTheme.textPrimary,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: AppFontSize.micro,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
