import 'package:flutter/material.dart';

import '../services/user_preferences_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'citas_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import 'servicios_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  static const _looks = <_NailLook>[
    _NailLook(
      id: 'rose-french',
      title: 'French rosado',
      detail: 'Rosa translúcido · clásico',
      imageUrl: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=800&q=80',
    ),
    _NailLook(
      id: 'soft-nude',
      title: 'Nude natural',
      detail: 'Tono arena · minimalista',
      imageUrl: 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=800&q=80',
    ),
    _NailLook(
      id: 'berry-glaze',
      title: 'Berry glaze',
      detail: 'Ciruela brillante · temporada',
      imageUrl: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=800&q=80',
    ),
    _NailLook(
      id: 'pearl-detail',
      title: 'Detalle perlado',
      detail: 'Perla sutil · especial',
      imageUrl: 'https://images.unsplash.com/photo-1600948836101-f9ffda59d250?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  Set<String> _favorites = {};
  String? _error;
  bool _loading = true;
  bool _showInspiration = false;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final favorites = await UserPreferencesStore.instance.loadFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(_NailLook look) async {
    if (_saving.contains(look.id)) return;
    final next = Set<String>.from(_favorites);
    final remove = !next.add(look.id);
    if (remove) next.remove(look.id);
    setState(() => _saving.add(look.id));
    try {
      await UserPreferencesStore.instance.saveFavorites(next);
      if (!mounted) return;
      setState(() {
        _favorites = next;
        _saving.remove(look.id);
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _saving.remove(look.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el favorito: $error')),
      );
    }
  }

  void _navigate(int index) {
    final page = switch (index) {
      0 => const HomeScreen(),
      1 => const ServiciosScreen(),
      2 => const CitasScreen(),
      _ => const PerfilScreen(),
    };
    if (index != 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleLooks = _looks
        .where((look) => _showInspiration || _favorites.contains(look.id))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              onProfileTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const PerfilScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  Text('TU COLECCIÓN', style: AppTheme.labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Favoritos',
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Guarda tonos y diseños para encontrar inspiración en tu próxima visita.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Guardados (${_favorites.length})'),
                        selected: !_showInspiration,
                        onSelected: (_) =>
                            setState(() => _showInspiration = false),
                        selectedColor: AppTheme.softPink,
                        labelStyle: TextStyle(
                          color: !_showInspiration
                              ? AppTheme.accent
                              : AppTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                      ),
                      ChoiceChip(
                        label: const Text('Inspiración'),
                        selected: _showInspiration,
                        onSelected: (_) =>
                            setState(() => _showInspiration = true),
                        selectedColor: AppTheme.softPink,
                        labelStyle: TextStyle(
                          color: _showInspiration
                              ? AppTheme.accent
                              : AppTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  else if (_error != null)
                    _FavoritesMessage(
                      icon: Icons.error_outline,
                      title: 'No pudimos cargar tus favoritos',
                      message: _error!,
                      actionLabel: 'Intentar de nuevo',
                      onAction: _loadFavorites,
                    )
                  else if (visibleLooks.isEmpty)
                    _FavoritesMessage(
                      icon: Icons.favorite_border,
                      title: 'Tu colección empieza aquí',
                      message: 'Explora la inspiración y toca el corazón para guardar los diseños que te gustan.',
                      actionLabel: 'Ver inspiración',
                      onAction: () => setState(() => _showInspiration = true),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 600 ? 3 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleLooks.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemBuilder: (context, index) {
                            final look = visibleLooks[index];
                            return _LookCard(
                              look: look,
                              isFavorite: _favorites.contains(look.id),
                              saving: _saving.contains(look.id),
                              onFavoriteTap: () => _toggleFavorite(look),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ServiciosScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.spa_outlined),
                    label: const Text('Explorar servicios del estudio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppTheme.softPink),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 3, onTap: _navigate),
    );
  }
}

class _NailLook {
  const _NailLook({
    required this.id,
    required this.title,
    required this.detail,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String detail;
  final String imageUrl;
}

class _LookCard extends StatelessWidget {
  const _LookCard({
    required this.look,
    required this.isFavorite,
    required this.saving,
    required this.onFavoriteTap,
  });

  final _NailLook look;
  final bool isFavorite;
  final bool saving;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.text.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  look.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppTheme.softPink,
                    child: Center(
                      child: Icon(
                        Icons.spa_outlined,
                        color: AppTheme.accent,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: AppTheme.surface.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: isFavorite
                          ? 'Quitar de favoritos'
                          : 'Guardar en favoritos',
                      onPressed: saving ? null : onFavoriteTap,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accent,
                              ),
                            )
                          : Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: AppTheme.accent,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  look.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  look.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesMessage extends StatelessWidget {
  const _FavoritesMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.softPink,
            foregroundColor: AppTheme.accent,
            child: Icon(icon),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.titleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
