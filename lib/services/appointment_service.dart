import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/appointment.dart';
import '../utils/date_time.dart';

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
  static const _timeout = Duration(seconds: 15);
  static const _invalidResponse = 'El servidor devolvió una respuesta inválida.';

  final http.Client _client = http.Client();

  Uri _endpoint(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$base/$path').replace(queryParameters: query);
  }

  Future<AppointmentAvailability> getAvailability({
    required DateTime date,
    required int serviceId,
  }) async {
    final dateValue = _formatDate(date);
    final body = _asMap(
      await _send(
        () => _client.get(
          _endpoint('availability', {
            'date': dateValue,
            'serviceId': '$serviceId',
          }),
        ),
      ),
    );
    return AppointmentAvailability(
      morning: _parseTimes(dateValue, body['morning']),
      afternoon: _parseTimes(dateValue, body['afternoon']),
      price: body['costo'] is num ? (body['costo'] as num).toDouble() : null,
    );
  }

  Future<Appointment> createAppointment({
    required int serviceId,
    required DateTime date,
    required DateTime time,
    required String token,
    String? customerPhone,
  }) async {
    final body = _asMap(
      await _send(
        () => _client.post(
          _endpoint('appointments'),
          headers: {
            'content-type': 'application/json',
            'authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'servicio_id': serviceId,
            'fecha': _formatDate(date),
            'hora': _formatTime(time),
            if (customerPhone != null && customerPhone.trim().isNotEmpty)
              'telefono': customerPhone.trim(),
          }),
        ),
      ),
    );
    return Appointment.fromJson(body);
  }

  /// Citas de la usuaria, de la más antigua a la más reciente.
  Future<List<Appointment>> loadMine({required String token}) async {
    if (token.isEmpty) {
      throw const AppointmentServiceException(
        'Inicia sesión para consultar tus citas.',
      );
    }
    final values = await _send(
      () => _client.get(
        _endpoint('appointments/mine'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    if (values is! List) {
      throw const AppointmentServiceException(_invalidResponse);
    }
    return values.map((value) {
      if (value is! Map<String, dynamic>) {
        throw const AppointmentServiceException(_invalidResponse);
      }
      return Appointment.fromJson(value);
    }).toList()..sort((first, second) {
      final firstStart = first.start;
      final secondStart = second.start;
      if (firstStart == null || secondStart == null) return 0;
      return firstStart.compareTo(secondStart);
    });
  }

  /// Envía la petición y traduce los fallos de red a mensajes para la usuaria.
  Future<Object?> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw AppointmentServiceException(
        decoded is Map<String, dynamic> && decoded['error'] is String
            ? decoded['error'] as String
            : 'No se pudo completar la operación (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (error) {
      debugPrint('Sin conexion con ${AppConfig.apiBaseUrl}: ${error.message}');
      throw AppointmentServiceException(
        'No pudimos conectar con el servidor (${AppConfig.apiBaseUrl}).',
      );
    } on TimeoutException {
      throw const AppointmentServiceException(
        'El servidor tardó demasiado en responder.',
      );
    } on FormatException {
      throw const AppointmentServiceException(_invalidResponse);
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const AppointmentServiceException(_invalidResponse);
  }

  List<DateTime> _parseTimes(String date, Object? values) {
    if (values is! List) {
      throw const AppointmentServiceException(_invalidResponse);
    }
    return values.map((value) {
      if (value is! String || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
        throw const AppointmentServiceException(_invalidResponse);
      }
      final parsed = parseStudioDateTime(date, value);
      if (parsed == null) {
        throw const AppointmentServiceException(_invalidResponse);
      }
      return parsed;
    }).toList();
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
