import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/studio_service.dart';
import '../navigation/tabs.dart';
import '../services/service_catalog_service.dart';
import '../services/user_preferences_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'citas_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<StudioService> _services = [];
  Set<int> _favoriteIds = {};
  String? _error;
  bool _loading = true;
  final Set<int> _savingIds = {};

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
      final favoriteIds = await UserPreferencesStore.instance
          .loadFavoriteServiceIds();
      if (favoriteIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _favoriteIds = favoriteIds;
          _services = [];
          _loading = false;
        });
        return;
      }

      final catalog = await Future.wait([
        ServiceCatalogService.instance.loadServices(category: 'manicura'),
        ServiceCatalogService.instance.loadServices(category: 'pedicura'),
      ]);
      final services = catalog
          .expand((categoryServices) => categoryServices)
          .where((service) => favoriteIds.contains(service.id))
          .toList();
      if (!mounted) return;
      setState(() {
        _favoriteIds = favoriteIds;
        _services = services;
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

  Future<void> _toggleFavorite(StudioService service) async {
    if (_savingIds.isNotEmpty || !_savingIds.add(service.id)) return;
    final next = Set<int>.from(_favoriteIds)..remove(service.id);
    setState(() {});
    try {
      await UserPreferencesStore.instance.saveFavoriteServiceIds(next);
      if (!mounted) return;
      setState(() {
        _favoriteIds = next;
        _services = _services.where((item) => item.id != service.id).toList();
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo quitar el favorito: $error')),
      );
    } finally {
      _savingIds.remove(service.id);
      if (mounted) setState(() {});
    }
  }

  void _reserve(StudioService service) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CitasScreen(
          serviceId: service.id,
          serviceName: service.name,
          serviceCost: service.cost,
          serviceDurationMinutes: service.durationMinutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(onBack: () => Navigator.maybePop(context)),
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
                    'Guarda servicios para encontrarlos fácilmente al reservar.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                  else if (_services.isEmpty)
                    _FavoritesMessage(
                      icon: Icons.favorite_border,
                      title: 'Aún no tienes servicios favoritos',
                      message: 'Explora el catálogo y toca el corazón para guardar un servicio.',
                      actionLabel: 'Explorar servicios',
                      onAction: () => openTab(context, 1),
                    )
                  else
                    ..._services.map(
                      (service) => _FavoriteServiceCard(
                        service: service,
                        saving: _savingIds.contains(service.id),
                        savingAny: _savingIds.isNotEmpty,
                        onRemove: () => _toggleFavorite(service),
                        onReserve: () => _reserve(service),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onTap: (index) => openTab(context, index),
      ),
    );
  }
}

class _FavoriteServiceCard extends StatelessWidget {
  const _FavoriteServiceCard({
    required this.service,
    required this.saving,
    required this.savingAny,
    required this.onRemove,
    required this.onReserve,
  });

  final StudioService service;
  final bool saving;
  final bool savingAny;
  final VoidCallback onRemove;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.currency(
      locale: 'es_MX',
      name: 'MXN',
      symbol: r'$',
      decimalDigits: 2,
    ).format(service.cost);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.category.toUpperCase(),
                      style: AppTheme.labelStyle.copyWith(fontSize: 9),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.name,
                      style: AppTheme.titleStyle.copyWith(fontSize: 19),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar de favoritos',
                onPressed: savingAny ? null : onRemove,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accent,
                        ),
                      )
                    : const Icon(Icons.favorite, color: AppTheme.accent),
              ),
            ],
          ),
          if (service.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              service.description!,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${service.durationMinutes} min',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
              Text(
                '$price MXN',
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(onPressed: onReserve, child: const Text('RESERVAR')),
            ],
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
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.titleStyle.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
