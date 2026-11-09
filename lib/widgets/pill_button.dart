import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.button,
        foregroundColor: AppTheme.surface,
        disabledBackgroundColor: AppTheme.disabled,
        disabledForegroundColor: AppTheme.surface,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (icon != null) ...[
            const SizedBox(width: 10),
            Icon(icon, size: 18),
          ],
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryPill extends StatelessWidget {
  const SecondaryPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.text,
        backgroundColor: AppTheme.surface,
        side: BorderSide(color: AppTheme.text.withValues(alpha: 0.08)),
        minimumSize: const Size(0, 46),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 17)],
        ],
      ),
    );
  }
}
