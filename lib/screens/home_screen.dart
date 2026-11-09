import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/pill_button.dart';
import 'citas_screen.dart';
import 'perfil_screen.dart';
import 'servicios_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, int index) {
    final page = switch (index) {
      1 => ServiciosScreen(),
      2 => const CitasScreen(),
      3 => PerfilScreen(),
      _ => const HomeScreen(),
    };
    if (index != 0) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.workspace_premium_outlined, 'Calidad Pure'),
      (Icons.auto_awesome_outlined, 'Nail Art'),
      (Icons.spa_outlined, 'Cuidado Spa'),
    ];
    const gallery = [
      (
        'Manicura y esmalte',
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
      ),
      (
        'Pedicura',
        'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=900&q=80',
      ),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              onProfileTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => PerfilScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => SecondaryPill(
                        label: 'Menú',
                        icon: Icons.menu,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: const ShapeDecoration(
                        color: AppTheme.softPink,
                        shape: StadiumBorder(),
                      ),
                      child: Text(
                        'TEMPORADA PRIMAVERA',
                        style: AppTheme.labelStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.heroPink, AppTheme.softPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ANNE SIGNATURE', style: AppTheme.labelStyle),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            text: 'Lujo Sutil &\n',
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 31,
                              height: 1.1,
                            ),
                            children: [
                              TextSpan(
                                text: 'Arte Juvenil',
                                style: AppTheme.titleStyle.copyWith(
                                  fontSize: 30,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Diseños de autor y cuidado personalizado para realzar tu belleza natural.',
                          style: TextStyle(color: AppTheme.muted, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 180,
                          child: PillButton(
                            label: 'Cita online',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const CitasScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: benefits.map((item) {
                      return Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.text.withValues(
                                      alpha: 0.04,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(item.$1, color: AppTheme.accent),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              item.$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.text,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Fotos de Estudio',
                    style: AppTheme.titleStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: gallery.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: item == gallery.first ? 7 : 0,
                            left: item == gallery.last ? 7 : 0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.text.withValues(alpha: 0.04),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: AspectRatio(
                                    aspectRatio: 0.92,
                                    child: Image.network(
                                      item.$2,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const ColoredBox(
                                            color: AppTheme.softPink,
                                            child: Icon(
                                              Icons.spa_outlined,
                                              color: AppTheme.accent,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.$1,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.softPink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      '“Tus manos son tu primera carta de presentación.”',
                      textAlign: TextAlign.center,
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }
}
