import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anne_nail_studio/widgets/preferences_section.dart';

void main() {
  testWidgets('shows preferences and forwards taps to each destination', (
    tester,
  ) async {
    final tappedDestinations = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreferencesSection(
            onAppointmentsTap: () => tappedDestinations.add('appointments'),
            onFavoritesTap: () => tappedDestinations.add('favorites'),
            onSettingsTap: () => tappedDestinations.add('settings'),
          ),
        ),
      ),
    );

    expect(find.text('PREFERENCIAS Y CUIDADO'), findsOneWidget);
    expect(find.text('Historial, estados y reagendamiento'), findsOneWidget);
    expect(find.text('Sets guardados, tonos e inspiración'), findsOneWidget);
    expect(find.text('Perfil, notificaciones e idioma'), findsOneWidget);

    await tester.tap(find.text('Mis citas'));
    await tester.tap(find.text('Favoritos'));
    await tester.tap(find.text('Ajustes'));

    expect(tappedDestinations, ['appointments', 'favorites', 'settings']);
  });
}
