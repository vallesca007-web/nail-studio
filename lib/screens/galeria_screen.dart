import 'package:flutter/material.dart';

class GaleriaScreen extends StatelessWidget {
  const GaleriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        backgroundColor: const Color(0xFFF8C8DC),
        foregroundColor: const Color(0xFF4A4A4A),
      ),
      body: const Center(
        child: Text(
          'Galería',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
      ),
    );
  }
}
