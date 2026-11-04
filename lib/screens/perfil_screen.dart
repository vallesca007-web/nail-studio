import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const pinkSoft = Color(0xFFF8C8DC);
    const pinkMain = Color(0xFFF4A6C1);
    const textDark = Color(0xFF4A4A4A);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: pinkSoft,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text('Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(55),
                border: Border.all(color: pinkMain, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: pinkSoft.withAlpha(140),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline,
                size: 52,
                color: textDark,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'perfil',
              style: TextStyle(
                color: textDark,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
