import 'package:flutter/material.dart';

import 'citas_screen.dart';
import 'contacto_screen.dart';
import 'galeria_screen.dart';
import 'login_screen.dart';
import 'servicios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _servicios = const [
    {'icono': Icons.brush_outlined, 'nombre': 'Manicure'},
    {'icono': Icons.spa_outlined, 'nombre': 'Pedicure'},
    {'icono': Icons.auto_fix_high_outlined, 'nombre': 'Uñas acrílicas'},
    {'icono': Icons.palette_outlined, 'nombre': 'Diseño de uñas'},
  ];

  final List<int> _galeriaItems = [1, 2, 3, 4];

  void _abrirPantalla(Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
  }

  void _mostrarDialogoCerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    const pinkSoft = Color(0xFFF8C8DC);
    const pinkMain = Color(0xFFF4A6C1);
    const textDark = Color(0xFF4A4A4A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pinkMain, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenida a Anne Nails',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cuida tus uñas con estilo, brillo y comodidad.',
                  style: TextStyle(fontSize: 14, color: textDark),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => _abrirPantalla(const CitasScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pinkMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Agendar cita'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: pinkSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: pinkMain, width: 2),
            ),
            child: const Icon(Icons.favorite_border, size: 40, color: textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildServicioCard(Map<String, dynamic> servicio) {
    const textDark = Color(0xFF4A4A4A);
    const pinkMain = Color(0xFFF4A6C1);

    return GestureDetector(
      onTap: () => _abrirPantalla(const ServiciosScreen()),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pinkMain, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(servicio['icono'] as IconData, size: 38, color: pinkMain),
            const SizedBox(height: 12),
            Text(
              servicio['nombre'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaleriaItem(int index) {
    const pinkMain = Color(0xFFF4A6C1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pinkMain, width: 1.5),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 42, color: Color(0xFFB9B3B5)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    const textDark = Color(0xFF4A4A4A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pinkSoft = Color(0xFFF8C8DC);
    const pinkMain = Color(0xFFF4A6C1);
    const textDark = Color(0xFF4A4A4A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anne Nails'),
        backgroundColor: pinkSoft,
        foregroundColor: textDark,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: pinkSoft),
              child: Center(
                child: Text(
                  'Anne Nails',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Servicios'),
              onTap: () {
                Navigator.pop(context);
                _abrirPantalla(const ServiciosScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _abrirPantalla(const GaleriaScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Agendar cita'),
              onTap: () {
                Navigator.pop(context);
                _abrirPantalla(const CitasScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.call_outlined),
              title: const Text('Contacto'),
              onTap: () {
                Navigator.pop(context);
                _abrirPantalla(const ContactoScreen());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoCerrarSesion();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 26),
              _buildSectionTitle('Nuestros servicios'),
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _servicios.length,
                  itemBuilder: (context, index) {
                    return _buildServicioCard(_servicios[index]);
                  },
                ),
              ),
              const SizedBox(height: 26),
              _buildSectionTitle('Galería'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _galeriaItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return _buildGaleriaItem(_galeriaItems[index]);
                },
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  onPressed: () => _abrirPantalla(const GaleriaScreen()),
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  label: const Text('Ver más'),
                  style: TextButton.styleFrom(foregroundColor: pinkMain),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _abrirPantalla(const ContactoScreen()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: pinkMain, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Contacto',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
}
