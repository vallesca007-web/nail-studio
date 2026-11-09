import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'app_session.dart';

const _calendarScope = 'https://www.googleapis.com/auth/calendar.events';

class CalendarPermissionException implements Exception {
  const CalendarPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalendarNetworkException implements Exception {
  const CalendarNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalendarSignInCancelledException implements Exception {
  const CalendarSignInCancelledException();
}

class GoogleCalendarService {
  GoogleCalendarService._();

  static final GoogleCalendarService instance = GoogleCalendarService._();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;
  GoogleSignInAccount? _account;
  http.Client? _authorizedClient;
  calendar.CalendarApi? _api;

  bool get isSignedIn => _account != null;

  Future<GoogleSignInAccount> signIn() async {
    try {
      await (_initialization ??= _googleSignIn.initialize(
        clientId: AppConfig.googleClientId,
        serverClientId: AppConfig.googleServerClientId,
      ));
      final account = await _googleSignIn.authenticate(
        scopeHint: const [_calendarScope],
      );
      final authorization =
          await account.authorizationClient.authorizationForScopes(const [
            _calendarScope,
          ]) ??
          await account.authorizationClient.authorizeScopes(const [
            _calendarScope,
          ]);
      _account = account;
      AppSession.instance.setGoogleUser(
        name: account.displayName ?? account.email,
        emailAddress: account.email,
        imageUrl: account.photoUrl,
      );
      _authorization = authorization;
      return account;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const CalendarSignInCancelledException();
      }
      throw CalendarPermissionException(
        'No se pudo completar el acceso a Google. Verifica los permisos e inténtalo de nuevo.',
      );
    }
  }

  GoogleSignInClientAuthorization? _authorization;

  Future<calendar.CalendarApi> _calendarApi() async {
    if (_account == null) {
      throw const CalendarPermissionException(
        'Inicia sesión con Google para consultar el calendario.',
      );
    }
    final authorization =
        _authorization ??
        await _account!.authorizationClient.authorizationForScopes(const [
          _calendarScope,
        ]);
    if (authorization == null) {
      throw const CalendarPermissionException(
        'Google Calendar necesita autorización para administrar las citas.',
      );
    }
    _authorization = authorization;
    if (_api == null) {
      _authorizedClient = authorization.authClient(
        scopes: const [_calendarScope],
      );
      _api = calendar.CalendarApi(_authorizedClient!);
    }
    return _api!;
  }

  Future<List<calendar.TimePeriod>> getBusySlots(DateTime day) async {
    try {
      final api = await _calendarApi();
      final start = DateTime(day.year, day.month, day.day);
      final response = await api.freebusy.query(
        calendar.FreeBusyRequest(
          timeMin: start.toUtc(),
          timeMax: start.add(const Duration(days: 1)).toUtc(),
          timeZone: AppConfig.timeZone,
          items: [calendar.FreeBusyRequestItem(id: AppConfig.calendarId)],
        ),
      );
      final studioCalendar = response.calendars?[AppConfig.calendarId];
      if (studioCalendar?.errors?.isNotEmpty ?? false) {
        throw const CalendarPermissionException(
          'No se pudo consultar la agenda del estudio. Verifica los permisos del calendario.',
        );
      }
      return studioCalendar?.busy ?? const [];
    } on calendar.DetailedApiRequestError catch (error) {
      if (error.status == 401 || error.status == 403) {
        throw const CalendarPermissionException(
          'No hay permisos para consultar la agenda del estudio. Revisa la configuración de Google Calendar.',
        );
      }
      throw CalendarNetworkException(
        'Google Calendar respondió con un error (${error.status ?? 'sin código'}).',
      );
    } on http.ClientException {
      throw const CalendarNetworkException(
        'No pudimos conectar con Google Calendar. Revisa tu conexión.',
      );
    }
  }

  Future<List<DateTime>> getAvailableSlots(
    DateTime day,
    Duration serviceDuration,
  ) async {
    final busySlots = await getBusySlots(day);
    final dayStart = DateTime(day.year, day.month, day.day);
    final opening = dayStart.add(Duration(hours: AppConfig.openingHour));
    final closing = dayStart.add(
      Duration(hours: AppConfig.closingHour, minutes: AppConfig.closingMinute),
    );
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final available = <DateTime>[];

    if (day.weekday == DateTime.sunday) return available;
    for (var start = opening; !start.add(serviceDuration).isAfter(closing);) {
      final end = start.add(serviceDuration);
      final hasConflict = busySlots.any((busy) {
        final busyStart = busy.start;
        final busyEnd = busy.end;
        return busyStart != null &&
            busyEnd != null &&
            start.isBefore(busyEnd) &&
            end.isAfter(busyStart);
      });
      if ((!isToday || start.isAfter(now)) && !hasConflict) {
        available.add(start);
      }
      start = start.add(AppConfig.appointmentInterval);
    }
    return available;
  }

  List<DateTime> getOfficeSlots(DateTime day, Duration serviceDuration) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final opening = dayStart.add(Duration(hours: AppConfig.openingHour));
    final closing = dayStart.add(
      Duration(hours: AppConfig.closingHour, minutes: AppConfig.closingMinute),
    );
    final now = DateTime.now();
    final isToday =
        dayStart.year == now.year &&
        dayStart.month == now.month &&
        dayStart.day == now.day;
    final slots = <DateTime>[];
    if (day.weekday == DateTime.sunday) return slots;
    for (var start = opening; !start.add(serviceDuration).isAfter(closing);) {
      if (!isToday || start.isAfter(now)) slots.add(start);
      start = start.add(AppConfig.appointmentInterval);
    }
    return slots;
  }

  Future<String> createAppointment({
    required String serviceName,
    required DateTime start,
    required Duration duration,
    required String customerName,
    required String customerEmail,
  }) async {
    try {
      final api = await _calendarApi();
      final event = await api.events.insert(
        calendar.Event(
          summary: 'Cita Anne Nails · $serviceName',
          description:
              'Clienta: $customerName\nCorreo: $customerEmail\nServicio: $serviceName',
          start: calendar.EventDateTime(
            dateTime: start,
            timeZone: AppConfig.timeZone,
          ),
          end: calendar.EventDateTime(
            dateTime: start.add(duration),
            timeZone: AppConfig.timeZone,
          ),
          attendees: [
            calendar.EventAttendee(email: AppConfig.studioEmail),
            if (customerEmail.isNotEmpty &&
                customerEmail != AppConfig.studioEmail)
              calendar.EventAttendee(email: customerEmail),
          ],
          reminders: calendar.EventReminders(
            useDefault: false,
            overrides: [
              calendar.EventReminder(method: 'email', minutes: 24 * 60),
            ],
          ),
        ),
        AppConfig.calendarId,
        sendUpdates: 'all',
      );
      final eventId = event.id;
      if (eventId == null || eventId.isEmpty) {
        throw StateError(
          'Google Calendar no devolvió el identificador de la cita.',
        );
      }
      return eventId;
    } on calendar.DetailedApiRequestError catch (error) {
      if (error.status == 401 || error.status == 403) {
        throw const CalendarPermissionException(
          'Google Calendar no permite crear la cita. Revisa los permisos del calendario.',
        );
      }
      throw CalendarNetworkException(
        'Google Calendar respondió con un error (${error.status ?? 'sin código'}).',
      );
    } on http.ClientException {
      throw const CalendarNetworkException(
        'No pudimos guardar la cita por un problema de conexión.',
      );
    }
  }

  Future<void> openCalendarEvent(String eventId) async {
    final api = await _calendarApi();
    final event = await api.events.get(AppConfig.calendarId, eventId);
    final url = event.htmlLink;
    if (url == null ||
        !await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
      throw StateError('No se pudo abrir la cita en Google Calendar.');
    }
  }

  Future<void> signOut() async {
    if (_account != null) {
      await (_initialization ??= _googleSignIn.initialize(
        clientId: AppConfig.googleClientId,
        serverClientId: AppConfig.googleServerClientId,
      ));
      await _googleSignIn.signOut();
    }
    _account = null;
    _authorization = null;
    _api = null;
    _authorizedClient?.close();
    _authorizedClient = null;
    AppSession.instance.setGuest();
  }
}
