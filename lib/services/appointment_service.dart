import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/appointment.dart';

class AppointmentAvailability {
  const AppointmentAvailability({
    required this.morning,
    required this.afternoon,
    this.price,
  });

  final List<DateTime> morning;
  final List<DateTime> afternoon;
  final double? price;

  List<DateTime> get all => [...morning, ...afternoon];
}

class AppointmentServiceException implements Exception {
  const AppointmentServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AppointmentService {
  AppointmentService._();

  static final AppointmentService instance = AppointmentService._();
  final http.Client _client = http.Client();

  Uri _endpoint(String path) {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$base/$path');
  }

  Future<AppointmentAvailability> getAvailability({
    required DateTime date,
    required String serviceId,
  }) async {
    final dateValue =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    try {
      final response = await _client
          .get(
            _endpoint('availability').replace(
              queryParameters: {'date': dateValue, 'serviceId': serviceId},
            ),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decodeResponse(response);
      return AppointmentAvailability(
        morning: _parseTimes(dateValue, body['morning']),
        afternoon: _parseTimes(dateValue, body['afternoon']),
        price: body['price'] is num ? (body['price'] as num).toDouble() : null,
      );
    } on http.ClientException {
      throw const AppointmentServiceException(
        'No pudimos conectar con el servidor de reservas.',
      );
    } on TimeoutException {
      throw const AppointmentServiceException(
        'El servidor de reservas tardó demasiado en responder.',
      );
    } on FormatException {
      throw const AppointmentServiceException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  Future<Appointment> createAppointment({
    required String serviceId,
    required DateTime date,
    required DateTime time,
    required String customerName,
    required String idToken,
    String? customerPhone,
  }) async {
    final dateValue =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final timeValue =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    try {
      final response = await _client
          .post(
            _endpoint('appointments'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'serviceId': serviceId,
              'date': dateValue,
              'time': timeValue,
              'customerName': customerName,
              if (customerPhone != null && customerPhone.trim().isNotEmpty)
                'customerPhone': customerPhone.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      return Appointment.fromJson(_decodeResponse(response));
    } on http.ClientException {
      throw const AppointmentServiceException(
        'No pudimos conectar con el servidor de reservas.',
      );
    } on TimeoutException {
      throw const AppointmentServiceException(
        'El servidor de reservas tardó demasiado en responder.',
      );
    } on FormatException {
      throw const AppointmentServiceException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const AppointmentServiceException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic> && decoded['error'] is String
          ? decoded['error'] as String
          : 'No se pudo completar la reserva (${response.statusCode}).';
      throw AppointmentServiceException(
        message,
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AppointmentServiceException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
    return decoded;
  }

  List<DateTime> _parseTimes(String date, Object? values) {
    if (values is! List<dynamic>) {
      throw const FormatException('La lista de horarios no es válida.');
    }
    return values.map((value) {
      if (value is! String || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
        throw const FormatException('Un horario del servidor no es válido.');
      }
      return DateTime.parse('${date}T$value:00');
    }).toList();
  }
}
