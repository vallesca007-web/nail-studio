import '../utils/date_time.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.serviceName,
    required this.fecha,
    required this.hora,
    required this.estado,
    this.eventUrl,
    this.serviceId = '',
    this.customerName = '',
    this.customerEmail = '',
    this.eventIdValue,
    this.reservationCodeValue,
    this.startDateTime,
    this.endDateTime,
  });

  final int id;
  final String serviceName;
  final String fecha;
  final String hora;
  final String estado;
  final String? eventUrl;
  final String serviceId;
  final String customerName;
  final String customerEmail;
  final String? eventIdValue;
  final String? reservationCodeValue;
  final DateTime? startDateTime;
  final DateTime? endDateTime;

  DateTime? get start => startDateTime ?? parseStudioDateTime(fecha, hora);
  DateTime? get end => endDateTime ?? start?.add(const Duration(minutes: 60));
  String get eventId => eventIdValue ?? (id > 0 ? '$id' : '');
  String get status => estado;
  String get reservationCode =>
      reservationCodeValue ?? id.toString().padLeft(6, '0');

  Appointment copyWith({String? estado}) => Appointment(
    id: id,
    serviceName: serviceName,
    fecha: fecha,
    hora: hora,
    estado: estado ?? this.estado,
    eventUrl: eventUrl,
    serviceId: serviceId,
    customerName: customerName,
    customerEmail: customerEmail,
    eventIdValue: eventIdValue,
    reservationCodeValue: reservationCodeValue,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'eventId': eventId,
    'serviceId': serviceId,
    'reservationCode': reservationCode,
    'eventUrl': eventUrl,
    'serviceName': serviceName,
    'fecha': fecha,
    'hora': hora,
    'estado': estado,
    'start': start?.toUtc().toIso8601String(),
    'end': end?.toUtc().toIso8601String(),
    'customerName': customerName,
    'customerEmail': customerEmail,
    'status': status,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final eventId = _text(json['eventId']);
    final idValue = json['id'];
    final id = idValue is num ? idValue.toInt() : int.tryParse(eventId) ?? 0;
    final parsedStart = _dateTime(json['start']);
    final parsedEnd = _dateTime(json['end']);
    final fecha = _text(json['fecha']);
    final hora = _text(json['hora']);
    final estado = _text(json['estado'] ?? json['status']);
    final serviceId = json['serviceId'] ?? json['servicio_id'];

    return Appointment(
      id: id,
      serviceName: _text(json['servicio'] ?? json['serviceName']),
      fecha: fecha,
      hora: hora,
      estado: estado.isEmpty ? 'pendiente' : estado,
      eventUrl: json['eventUrl'] is String ? json['eventUrl'] as String : null,
      serviceId: serviceId is String
          ? serviceId
          : serviceId is num
          ? serviceId.toString()
          : '',
      customerName: _text(json['customerName']),
      customerEmail: _text(json['customerEmail']),
      eventIdValue: eventId.isEmpty ? null : eventId,
      reservationCodeValue: json['reservationCode'] is String
          ? json['reservationCode'] as String
          : null,
      startDateTime: parsedStart,
      endDateTime: parsedEnd,
    );
  }
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

String _text(Object? value) => value is String ? value : '';
