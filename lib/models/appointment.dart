import '../utils/date_time.dart';

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

  // Null si la API devolvio una fecha o una hora imposibles de leer.
  DateTime? get start => parseStudioDateTime(fecha, hora);
  DateTime? get end => start?.add(const Duration(minutes: 60));
  String get reservationCode => id.toString().padLeft(6, '0');

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final estado = _text(json['estado']);
    return Appointment(
      id: json['id'] as int,
      serviceName: _text(json['servicio'] ?? json['serviceName']),
      fecha: _text(json['fecha']),
      hora: _text(json['hora']),
      estado: estado.isEmpty ? 'pendiente' : estado,
      eventUrl: json['eventUrl'] is String ? json['eventUrl'] as String : null,
    );
  }
}

String _text(Object? value) => value is String ? value : '';
