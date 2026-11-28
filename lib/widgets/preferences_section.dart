import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _iconBackground = Color(0xFFF5EFF0);
const _iconColor = Color(0xFF7A384D);
const _dividerColor = Color(0xFFF5E6EA);

class PreferencesSection extends StatelessWidget {
  const PreferencesSection({
    super.key,
    required this.onAppointmentsTap,
    required this.onFavoritesTap,
    required this.onSettingsTap,
  });

  final VoidCallback onAppointmentsTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERENCIAS Y CUIDADO',
          style: AppTheme.labelStyle.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: AppTheme.text.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppTheme.surface,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _PreferenceRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Mis citas',
                  subtitle: 'Historial, estados y reagendamiento',
                  onTap: onAppointmentsTap,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  endIndent: 16,
                  color: _dividerColor,
                ),
                _PreferenceRow(
                  icon: Icons.favorite,
                  title: 'Favoritos',
                  subtitle: 'Sets guardados, tonos e inspiración',
                  onTap: onFavoritesTap,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  endIndent: 16,
                  color: _dividerColor,
                ),
                _PreferenceRow(
                  icon: Icons.tune_rounded,
                  title: 'Ajustes',
                  subtitle: 'Perfil, notificaciones e idioma',
                  onTap: onSettingsTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      hoverColor: _iconColor.withValues(alpha: 0.045),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: _iconBackground,
              foregroundColor: _iconColor,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.muted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}
