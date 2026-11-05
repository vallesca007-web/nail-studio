import 'package:flutter/material.dart';

class MenuLateral extends StatelessWidget {
  final void Function(String opcion) alSeleccionar;

  const MenuLateral({super.key, required this.alSeleccionar});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {'label': 'Inicio', 'valor': 'inicio'},
      {'label': 'Servicios', 'valor': 'servicios'},
      {'label': 'Cita', 'valor': 'cita'},
      {'label': 'Perfil', 'valor': 'perfil'},
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'Menú',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ),
            ...opciones.map((opcion) {
              final label = opcion['label'] as String;
              final valor = opcion['valor'] as String;

              return ListTile(
                title: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                onTap: () => alSeleccionar(valor),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              );
            }),
          ],
        ),
      ),
    );
  }
}
