import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

<<<<<<< HEAD
import '../models/studio_service.dart';
import '../navigation/tabs.dart';
import '../services/service_catalog_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'citas_screen.dart';
=======
import '../navigation/tabs.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
>>>>>>> origin/main
import 'perfil_screen.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key, this.categoria});

<<<<<<< HEAD
  final String? categoria;

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  late String _category;
  List<StudioService> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _category = widget.categoria ?? 'manicura';
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final services = await ServiceCatalogService.instance.loadServices(
        category: _category,
      );
      if (!mounted) return;
      setState(() {
        _services = services;
        _loading = false;
      });
    } on ServiceCatalogException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _selectCategory(String category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      _services = [];
    });
    _loadServices();
  }

=======
  static const List<(String, String, String, String)> _services = [
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

>>>>>>> origin/main
  @override
  Widget build(BuildContext context) {
    final title = _category == 'manicura' ? 'Manicura' : 'Pedicura';
    final groups = <String, List<StudioService>>{};
    for (final service in _services) {
      groups.putIfAbsent(service.group, () => []).add(service);
    }

    var firstNumber = 1;
    final groupCards = groups.entries.map((entry) {
      final start = firstNumber;
      firstNumber += entry.value.length;
      return _ServiceGroupCard(
        title: entry.key,
        services: entry.value,
        firstNumber: start,
        onReserve: _reserve,
      );
    }).toList();

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
                  Text('SERVICIOS PARA TI', style: AppTheme.labelStyle),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  if (widget.categoria == null) ...[
                    const SizedBox(height: 16),
                    _CategoryTabs(
                      selected: _category,
                      onSelected: _selectCategory,
                    ),
                  ] else ...[
                    const SizedBox(height: 7),
                    Text(
                      'Elige el servicio ideal para tu próxima cita.',
                      style: TextStyle(color: AppTheme.muted, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  else if (_error != null)
                    _CatalogError(message: _error!, onRetry: _loadServices)
                  else if (_services.isEmpty)
                    const _CatalogEmpty()
                  else
                    ...groupCards,
                  const SizedBox(height: 4),
                  _StudioContactCard(onTap: _contactStudio),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onTap: (index) => openTab(context, index),
<<<<<<< HEAD
      ),
    );
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

  Future<void> _contactStudio() async {
    final uri = Uri.https('wa.me', '/529981361031', {
      'text': 'Hola, quisiera consultar por un diseño o servicio.',
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CategoryTab(
          label: 'Manicura',
          selected: selected == 'manicura',
          onTap: () => onSelected('manicura'),
        ),
        const SizedBox(width: 10),
        _CategoryTab(
          label: 'Pedicura',
          selected: selected == 'pedicura',
          onTap: () => onSelected('pedicura'),
        ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? AppTheme.surface : AppTheme.text,
          backgroundColor: selected ? AppTheme.accent : AppTheme.surface,
          side: BorderSide(
            color: selected ? AppTheme.accent : AppTheme.softPink,
          ),
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 46),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ServiceGroupCard extends StatelessWidget {
  const _ServiceGroupCard({
    required this.title,
    required this.services,
    required this.firstNumber,
    required this.onReserve,
  });

  final String title;
  final List<StudioService> services;
  final int firstNumber;
  final ValueChanged<StudioService> onReserve;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: const ShapeDecoration(
                  color: AppTheme.softPink,
                  shape: StadiumBorder(),
                ),
                child: Text(
                  '${services.length} ${services.length == 1 ? 'servicio' : 'servicios'}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (var index = 0; index < services.length; index++) ...[
            _ServiceRow(
              service: services[index],
              number: firstNumber + index,
              onReserve: () => onReserve(services[index]),
            ),
            if (index < services.length - 1)
              Divider(height: 1, color: AppTheme.text.withValues(alpha: 0.09)),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.number,
    required this.onReserve,
  });

  final StudioService service;
  final int number;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.currency(
      locale: 'es_MX',
      name: 'MXN',
      symbol: r'$',
      decimalDigits: 2,
    ).format(service.cost);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 35,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: AppTheme.titleStyle.copyWith(
                    color: AppTheme.accent,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: AppTheme.titleStyle.copyWith(fontSize: 17),
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.only(left: 43),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: const ShapeDecoration(
                    color: AppTheme.softPink,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    '${service.durationMinutes} min',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$price MXN',
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: onReserve,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.surface,
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'RESERVAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  const _CatalogEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Todavía no hay servicios activos en esta categoría.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.muted),
      ),
    );
  }
}

class _StudioContactCard extends StatelessWidget {
  const _StudioContactCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const whatsappGreen = Color(0xFF25D366);
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: whatsappGreen,
                size: 36,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿No encuentras tu diseño?',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Contacta al estudio por WhatsApp',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '998 136 1031',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
=======
>>>>>>> origin/main
      ),
    );
  }
}
