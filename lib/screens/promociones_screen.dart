import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/promotion.dart';
import '../services/promotion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class PromocionesScreen extends StatefulWidget {
  const PromocionesScreen({super.key});

  @override
  State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
  List<Promotion> _promotions = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final promotions = await PromotionService.instance.loadPromotions();
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _loading = false;
      });
    } on PromotionServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
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
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
                children: [
                  Text('BENEFICIOS PARA TI', style: AppTheme.labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Promociones',
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ofertas especiales de Anne Nails Studio.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
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
                    _PromotionMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'No pudimos cargar las promociones',
                      message: _error!,
                      actionLabel: 'Intentar de nuevo',
                      onAction: _loadPromotions,
                    )
                  else if (_promotions.isEmpty)
                    const _PromotionMessage(
                      icon: Icons.local_offer_outlined,
                      title: 'Por ahora no hay promociones',
                      message: 'Vuelve pronto para descubrir las próximas ofertas del estudio.',
                    )
                  else
                    ..._promotions.map(
                      (promotion) => _PromotionCard(promotion: promotion),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final endDate = promotion.endDate;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, AppTheme.softPink],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.accent,
                child: Icon(Icons.local_offer_outlined),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: const ShapeDecoration(
                  color: AppTheme.surface,
                  shape: StadiumBorder(),
                ),
                child: Text(
                  promotion.badge,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            promotion.title,
            style: AppTheme.titleStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 7),
          Text(
            promotion.description,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (endDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Válida hasta ${DateFormat('d MMM yyyy', 'es').format(endDate)}',
              style: AppTheme.labelStyle.copyWith(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}

class _PromotionMessage extends StatelessWidget {
  const _PromotionMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
