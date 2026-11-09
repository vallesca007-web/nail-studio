import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'citas_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import 'servicios_screen.dart';

class ContactoScreen extends StatelessWidget {
  const ContactoScreen({super.key});

  void _navigate(BuildContext context, int index) {
    final page = switch (index) {
      0 => const HomeScreen(),
      1 => ServiciosScreen(),
      2 => const CitasScreen(),
      _ => PerfilScreen(),
    };
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Text('ESTAMOS PARA TI', style: AppTheme.labelStyle),
                  const SizedBox(height: 5),
                  Text(
                    'Contáctanos',
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(
                      children: [
                        _ContactRow(
                          icon: Icons.mail_outline,
                          title: 'Correo',
                          subtitle: 'Escríbenos para consultas y reservas.',
                        ),
                        Divider(height: 30),
                        _ContactRow(
                          icon: Icons.chat_bubble_outline,
                          title: 'WhatsApp',
                          subtitle: 'Coordinamos contigo personalmente.',
                        ),
                        Divider(height: 30),
                        _ContactRow(
                          icon: Icons.schedule_outlined,
                          title: 'Horario',
                          subtitle: 'Lunes a sábado · consulta disponibilidad.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.softPink,
          foregroundColor: AppTheme.accent,
          child: Icon(icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
