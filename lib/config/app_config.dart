class AppConfig {
  // TODO: Configurar los OAuth Client ID de las aplicaciones Android y web.
  static const googleClientId = 'YOUR_GOOGLE_OAUTH_CLIENT_ID';
  static const googleServerClientId = 'YOUR_GOOGLE_SERVER_CLIENT_ID';

  // TODO: Sustituir por el ID real del calendario del estudio.
  static const calendarId = 'YOUR_STUDIO_CALENDAR_ID';

  // TODO: Configurar un identificador IANA válido para la zona del estudio.
  static const timeZone = 'YOUR_IANA_TIME_ZONE';

  // TODO: Reemplazar por el correo que recibirá las invitaciones del estudio.
  static const studioEmail = 'YOUR_STUDIO_EMAIL';

  static const studioName = 'Anne Nails Studio';
  static const openingHour = 10;
  static const closingHour = 19;
  static const closingMinute = 30;
  static const appointmentInterval = Duration(minutes: 30);
  static const currencyCode = 'USD';

  // TODO: Confirmar el precio de este servicio y la moneda configurada.
  static const signatureServicePrice = 45.0;
  static const signatureServiceDuration = Duration(minutes: 60);
}
