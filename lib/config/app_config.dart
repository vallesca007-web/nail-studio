import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    const environmentValue = String.fromEnvironment('API_BASE_URL');
    if (environmentValue.isNotEmpty) {
      return environmentValue;
    }
    // 10.0.2.2 solo existe dentro del emulador Android; el resto usa localhost.
    final androidEmulator =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return androidEmulator
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }

  // Android resuelve el client nativo mediante el package name y SHA-1.
  static const googleClientId = '';
  static const googleServerClientId =
      '508896308195-h7r0cm8302k69n9hosmtu95qn93dn5mi.apps.googleusercontent.com';

  // TODO: Sustituir por el ID real del calendario del estudio.
  static const calendarId = 'YOUR_STUDIO_CALENDAR_ID';

  // TODO: Configurar un identificador IANA válido para la zona del estudio.
  static const timeZone = 'YOUR_IANA_TIME_ZONE';

  // TODO: Reemplazar por el correo que recibirá las invitaciones del estudio.
  static const studioEmail = 'YOUR_STUDIO_EMAIL';

  static const studioName = 'Anne Nail Studio';
<<<<<<< HEAD
  static const currencyCode = 'MXN';
=======
  static const currencyCode = 'USD';
>>>>>>> origin/main

  // Servicio que se reserva desde la app. Debe existir en la tabla servicios.
  static const signatureServiceId = 1;
  static const signatureServicePrice = 45.0;
  static const signatureServiceDuration = Duration(minutes: 60);
}
