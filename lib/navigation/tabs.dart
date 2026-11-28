import 'package:flutter/material.dart';

<<<<<<< HEAD
=======
import '../screens/citas_screen.dart';
>>>>>>> origin/main
import '../screens/home_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/servicios_screen.dart';

/// Cambia de pestaña reemplazando la ruta actual.
///
/// Así el tab bar no acumula pantallas en el historial y el gesto de volver
/// del sistema se comporta igual desde cualquier pestaña.
void openTab(BuildContext context, int index) {
  final page = switch (index) {
    0 => const HomeScreen(),
    1 => ServiciosScreen(),
<<<<<<< HEAD
    2 => PerfilScreen(),
=======
    2 => const CitasScreen(),
    3 => PerfilScreen(),
>>>>>>> origin/main
    _ => null,
  };
  if (page == null) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute<void>(builder: (_) => page),
  );
}
