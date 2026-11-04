import 'package:flutter/material.dart';

class ServiciosScreen extends StatelessWidget {
  ServiciosScreen({super.key});

  Widget _buildImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF5E8EB),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFFCB9BAA),
            size: 28,
          ),
        );
      },
    );
  }

  final List<Map<String, String>> _servicios = [
    {
      'titulo': 'Manicure exprés',
      'descripcion': 'Limpieza, forma y acabado elegante para un look siempre impecable.',
      'precio': 'Desde \$350',
      'imagen':
          'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'titulo': 'Pedicure spa',
      'descripcion': 'Relajación total y cuidado premium para tus pies.',
      'precio': '\$520',
      'imagen':
          'https://images.unsplash.com/photo-1600948836101-f9ffda59d250?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'titulo': 'Uñas acrílicas',
      'descripcion': 'Longitud, resistencia y diseño personalizado a tu estilo.',
      'precio': '\$700',
      'imagen':
          'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'titulo': 'Diseño premium',
      'descripcion': 'Arte detallado con acabados únicos y tendencias actuales.',
      'precio': '\$480',
      'imagen':
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const pinkSoft = Color(0xFFF8C8DC);
    const pinkMain = Color(0xFFF4A6C1);
    const textDark = Color(0xFF4A4A4A);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: pinkSoft,
        foregroundColor: textDark,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Anne Nails'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final available = width - 36;
          final itemWidth = (available - 18) / 2;
          final imageHeight = itemWidth * 0.9;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: GridView.builder(
                itemCount: _servicios.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: (itemWidth / (imageHeight + 120)).clamp(0.55, 0.9),
                ),
                itemBuilder: (context, index) {
                  final servicio = _servicios[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pinkMain, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: pinkSoft.withAlpha(90),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: imageHeight,
                          width: double.infinity,
                          child: _buildImage(servicio['imagen']!),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servicio['titulo']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Text(
                                    servicio['descripcion']!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7B6B70),
                                      fontSize: 11.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  servicio['precio']!,
                                  style: const TextStyle(
                                    color: pinkMain,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
