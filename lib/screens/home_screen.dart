import 'package:flutter/material.dart';

import '../navigation/tabs.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/pill_button.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _buildSeasonChip(),
                  const SizedBox(height: 14),
                  _buildHero(context),
                  const SizedBox(height: 26),
<<<<<<< HEAD
                  _buildServicesSection(context),
=======
                  Text(
                    'Fotos de Estudio',
                    style: AppTheme.titleStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(gallery.length, (index) {
                      final item = gallery[index];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == 0 ? 7 : 0,
                            left: index == gallery.length - 1 ? 7 : 0,
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
                    }),
                  ),
>>>>>>> origin/main
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
        onTap: (index) => openTab(context, index),
<<<<<<< HEAD
      ),
    );
  }

  Widget _buildSeasonChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: const ShapeDecoration(
          color: AppTheme.softPink,
          shape: StadiumBorder(),
        ),
        child: Text('TEMPORADA PRIMAVERA', style: AppTheme.labelStyle),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
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
              style: AppTheme.titleStyle.copyWith(fontSize: 31, height: 1.1),
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
                MaterialPageRoute<void>(builder: (_) => ServiciosScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTheme.titleStyle.copyWith(
              color: AppTheme.text,
              fontSize: 28,
            ),
            children: const [
              TextSpan(text: 'Nuestros '),
              TextSpan(
                text: 'Servicios',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cada experiencia tiene su propio mundo. Elige la tuya.',
          style: TextStyle(color: AppTheme.muted, height: 1.4, fontSize: 13),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 620) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _serviceCard(context, 'manicura')),
                  const SizedBox(width: 14),
                  Expanded(child: _serviceCard(context, 'pedicura')),
                ],
              );
            }
            return Column(
              children: [
                _serviceCard(context, 'manicura'),
                const SizedBox(height: 14),
                _serviceCard(context, 'pedicura'),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _serviceCard(BuildContext context, String category) {
    final isManicure = category == 'manicura';
    final title = isManicure ? 'Manicura' : 'Pedicura';
    final asset = isManicure
        ? 'assets/images/servicio_manicura.jpg'
        : 'assets/images/servicio_pedicura.jpg';
    final description = isManicure
        ? 'Manicura, esmaltado en gel y uñas acrílicas. Arte en tus manos.'
        : 'Pedicura con cuidado profundo y esmaltado. Pies suaves y radiantes.';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openCategory(context, category),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.text.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.text.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.asset(
                      asset,
                      width: double.infinity,
                      height: 185,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            width: double.infinity,
                            height: 185,
                            child: ColoredBox(color: AppTheme.softPink),
                          ),
                    ),
                  ),
                  Positioned(
                    right: 11,
                    top: 11,
                    child: Material(
                      color: AppTheme.surface,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Ver $title',
                        onPressed: () => _openCategory(context, category),
                        icon: const Icon(
                          Icons.north_east,
                          size: 19,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppTheme.titleStyle.copyWith(
                  color: AppTheme.text,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.muted,
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: AppTheme.text.withValues(alpha: 0.12)),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: FilledButton(
                    onPressed: () => _openCategory(context, category),
                    style: FilledButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      backgroundColor: AppTheme.softPink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VER EXPERIENCIA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(Icons.arrow_forward, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ServiciosScreen(categoria: category),
=======
>>>>>>> origin/main
      ),
    );
  }
}
