import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum AppButtonStyle { primary, secondary, ghost }

/// Botón único de la app.
///
/// Mide 54 px de alto para superar los 48 dp de área táctil que recomienda
/// Material, ocupa todo el ancho en acciones principales, responde con
/// vibración háptica y muestra un indicador mientras trabaja para que no se
/// pueda pulsar dos veces.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.expanded = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = switch (style) {
      AppButtonStyle.primary => (
        background: AppTheme.button,
        foreground: AppTheme.surface,
        border: BorderSide.none,
      ),
      AppButtonStyle.secondary => (
        background: AppTheme.surface,
        foreground: AppTheme.text,
        border: BorderSide(color: AppTheme.text.withValues(alpha: 0.12)),
      ),
      AppButtonStyle.ghost => (
        background: Colors.transparent,
        foreground: AppTheme.accent,
        border: BorderSide.none,
      ),
    };
    final enabled = onPressed != null && !loading;

    return SizedBox(
      width: expanded ? double.infinity : null,
      child: TextButton(
        onPressed: enabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
        style: TextButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          // Mientras carga conserva su color: se ve ocupado, no deshabilitado.
          disabledBackgroundColor: loading
              ? colors.background
              : (style == AppButtonStyle.primary
                    ? AppTheme.disabled
                    : colors.background),
          disabledForegroundColor: loading
              ? colors.foreground
              : AppTheme.muted,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          shape: const StadiumBorder(),
          side: colors.border,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
