import 'package:flutter/material.dart';

class GaleriaScreen extends StatelessWidget {
  GaleriaScreen({super.key});

  Widget _buildImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
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

  final List<String> _imagenes = [
    'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1600948836101-f9ffda59d250?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1521590832167-7ae6d1025f5d?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
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
            const Text('Galería'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: GridView.builder(
            itemCount: _imagenes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final imageUrl = _imagenes[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: pinkMain, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: pinkSoft.withAlpha(90),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(imageUrl),
              );
            },
          ),
        ),
      ),
    );
  }
}
