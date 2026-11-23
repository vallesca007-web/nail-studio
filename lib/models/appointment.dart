import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.serviceName,
    required this.fecha,
    required this.hora,
    required this.estado,
    this.eventUrl,
  });

  final int id;
  final String serviceName;
  final String fecha;
  final String hora;
  final String estado;
  final String? eventUrl;

  DateTime get start => DateTime.parse('$fecha' 'T$hora' ':00');
  DateTime get end => start.add(const Duration(minutes: 60));
  String get reservationCode => id.toString().padLeft(6, '0');
  String get eventId => id.toString();

  Map<String, Object?> toJson() => {
    'id': id,
    'servicio': serviceName,
    'fecha': fecha,
    'hora': hora,
    'estado': estado,
    'eventUrl': eventUrl,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as int,
    serviceName: json['servicio'] as String? ?? json['serviceName'] as String? ?? '',
    fecha: json['fecha'] as String? ?? '',
    hora: json['hora'] as String? ?? '',
    estado: json['estado'] as String? ?? 'pendiente',
    eventUrl: json['eventUrl'] as String?,
  );
}

class AppointmentStore {
  AppointmentStore._();

  static final AppointmentStore instance = AppointmentStore._();
  final http.Client _client = http.Client();

  Uri get _appointmentsUri => Uri.parse(
    '${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/appointments/mine',
  );

  Future<List<Appointment>> load({required String token}) async {
    if (token.trim().isEmpty) {
      throw const AppointmentStoreException(
        'Inicia sesión para consultar tus citas.',
      );
    }
    try {
      final response = await _client
          .get(
            _appointmentsUri,
            headers: {'authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      _checkResponse(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      return values
          .map((value) => Appointment.fromJson(value as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
    } on http.ClientException {
      throw const AppointmentStoreException(
        'No pudimos conectar con el servidor de citas.',
      );
    } on TimeoutException {
      throw const AppointmentStoreException(
        'El servidor de citas tardó demasiado en responder.',
      );
    } on FormatException {
      throw const AppointmentStoreException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'El servidor rechazó la operación (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['error'] case final String error when error.isNotEmpty) {
        message = error;
      }
    } on FormatException {
      // Si el servidor no envía JSON, se conserva el mensaje por código HTTP.
    } on TypeError {
      // Si el formato JSON no es un mapa, se conserva el mensaje por código HTTP.
    }
    throw AppointmentStoreException(message);
  }
}

class AppointmentStoreException implements Exception {
  const AppointmentStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
