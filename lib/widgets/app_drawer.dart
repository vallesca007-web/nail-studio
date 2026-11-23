import 'package:flutter/material.dart';

import '../screens/citas_screen.dart';
import '../screens/contacto_screen.dart';
import '../screens/servicios_screen.dart';
import '../theme/app_theme.dart';
import 'pill_button.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.86,
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Anne Nails • STUDIO',
                      style: AppTheme.titleStyle.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cuidado sofisticado, belleza en cada detalle.',
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _DrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Quiénes somos',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Anne Nails Studio',
                      children: const [Text('Cuidado, estilo y precisión.')],
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.spa_outlined,
                    title: 'Servicios',
                    subtitle:
                        'Manicura · Pedicura · Escultural · Softgel · Polygel',
                    onTap: () => _open(context, ServiciosScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
                    title: 'Promociones',
                    badge: 'Exclusivo',
                    onTap: () => _open(context, ServiciosScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.mail_outline,
                    title: 'Contáctanos',
                    onTap: () => _open(context, const ContactoScreen()),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.softPink,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ANNE SIGNATURE', style: AppTheme.labelStyle),
                        const SizedBox(height: 7),
                        Text(
                          'Exelence In All Services',
                          style: AppTheme.titleStyle.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Precisión artesanal para un acabado impecable.',
                          style: TextStyle(color: AppTheme.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: PillButton(
                label: 'Pide tu cita online',
                onPressed: () => _open(context, const CitasScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppTheme.softPink,
        foregroundColor: AppTheme.accent,
        child: Icon(icon, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.softPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
    );
  }
}
