import 'package:flutter/material.dart';

import 'catalogo_screen.dart';
import 'citas_screen.dart';
import 'perfil_screen.dart';
import 'servicios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _features = const [
    {'label': 'Calidad Pura', 'icon': '✦'},
    {'label': 'Nail Art', 'icon': '✧'},
    {'label': 'Cuidado Spa', 'icon': '❋'},
    {'label': 'Accesorios', 'icon': '✿'},
  ];

  final List<Map<String, String>> _gallery = const [
    {
      'title': 'Manicura y esmalte',
      'subtitle': 'Gel semipermanente...',
      'image': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Pedicura',
      'subtitle': 'Exfoliación & esmaltado.',
      'image': 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=900&q=80',
    },
  ];

  Widget _buildImage(String imageUrl, {double? width, double? height}) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
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

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CatalogoScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CitasScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PerfilScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F2F2);
    const pink = Color(0xFFEECCD6);
    const dark = Color(0xFF2C2A2A);
    const muted = Color(0xFF7B6B6F);
    const white = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        titleSpacing: 14,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pink, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Anne Nails',
              style: TextStyle(
                color: dark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: dark,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: white, size: 18),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          children: [
            const Row(
              children: [
                Icon(Icons.menu, color: dark, size: 26),
                Spacer(),
                Icon(Icons.arrow_back_ios_new_rounded, color: dark, size: 18),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5E6EB), Color(0xFFF1D8E1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COLECCIÓN EXCLUSIVA',
                    style: TextStyle(
                      letterSpacing: 1.2,
                      color: muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Lujo Sutil &\nAcabados Satin',
                    style: TextStyle(
                      color: dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      height: 1.1,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Diseños de autor, esmaltado semipermanente y tratamientos botánicos para realzar tu delicadeza natural.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => _open(CitasScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark,
                      foregroundColor: white,
                      minimumSize: const Size(170, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Cita online',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _features.map((item) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: pink, width: 1.2),
                          ),
                          child: Center(
                            child: Text(
                              item['icon']!,
                              style: const TextStyle(fontSize: 22, color: dark),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['label']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: dark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fotos de Estudio',
                  style: TextStyle(
                    color: dark,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => _open(CatalogoScreen()),
                  child: const Text(
                    'Ver catálogo',
                    style: TextStyle(
                      color: dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _gallery.map((item) {
                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        onTap: () => _open(ServiciosScreen()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                height: itemWidth * 0.85,
                                width: double.infinity,
                                child: _buildImage(item['image']!),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['title']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: dark,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['subtitle']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EEF2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite_outline, color: dark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        text: 'Tus manos son tu primera carta de presentación.\n',
                        style: TextStyle(color: dark, fontSize: 12, height: 1.5),
                        children: [
                          TextSpan(
                            text: 'Anne Nails Atelier © Cuidado personalizado',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: white,
          boxShadow: [
            BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => _onNavTap(0),
              icon: const Icon(Icons.home, color: dark),
            ),
            IconButton(
              onPressed: () => _onNavTap(1),
              icon: const Icon(Icons.grid_view_rounded, color: muted),
            ),
            IconButton(
              onPressed: () => _onNavTap(2),
              icon: const Icon(Icons.calendar_today_outlined, color: muted),
            ),
            IconButton(
              onPressed: () => _onNavTap(3),
              icon: const Icon(Icons.person_outline, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
