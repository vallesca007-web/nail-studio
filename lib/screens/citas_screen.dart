import 'package:flutter/material.dart';

class CitasScreen extends StatelessWidget {
  const CitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar cita'),
        backgroundColor: const Color(0xFFF8C8DC),
        foregroundColor: const Color(0xFF4A4A4A),
      ),
      body: const Center(
        child: Text(
          'Citas',
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
