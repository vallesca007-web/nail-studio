import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'citas_screen.dart';
import 'contacto_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';

class ServiciosScreen extends StatelessWidget {
  const ServiciosScreen({super.key});

  final List<(String, String, String, String)> _services = const [
    (
      'Manicura',
      'Preparación precisa de cutícula y acabado pulido.',
      'Desde 45 min',
      'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=900&q=80',
    ),
    (
      'Pedicura spa',
      'Ritual relajante de cuidado, exfoliación y esmaltado.',
      'Desde 60 min',
      'https://images.unsplash.com/photo-1600948836101-f9ffda59d250?auto=format&fit=crop&w=900&q=80',
    ),
    (
      'Nail art',
      'Diseños de autor con detalles hechos a mano.',
      'Desde 30 min',
      'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
    ),
    (
      'Softgel & Polygel',
      'Extensiones ligeras con forma y largo personalizados.',
      'Desde 90 min',
      'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  void _navigate(BuildContext context, int index) {
    if (index == 1) return;
    final page = switch (index) {
      0 => const HomeScreen(),
      2 => const CitasScreen(),
      3 => PerfilScreen(),
      _ => const ContactoScreen(),
    };
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text('SERVICIOS EXCLUSIVOS', style: AppTheme.labelStyle),
                  const SizedBox(height: 5),
                  Text(
                    'Rituales de belleza',
                    style: AppTheme.titleStyle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  ..._services.map((service) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.text.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(26),
                            ),
                            child: Image.network(
                              service.$4,
                              width: 112,
                              height: 132,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(
                                width: 112,
                                height: 132,
                                child: ColoredBox(
                                  color: AppTheme.softPink,
                                  child: Icon(
                                    Icons.spa_outlined,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.$3.toUpperCase(),
                                    style: AppTheme.labelStyle,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    service.$1,
                                    style: AppTheme.titleStyle.copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    service.$2,
                                    style: const TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Consultar precio',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
