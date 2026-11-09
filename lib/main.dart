import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/cargando_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anne Nails Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const CargandoScreen(),
    );
  }
}
