import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Appointment {
  const Appointment({
    required this.eventId,
    required this.serviceName,
    required this.start,
    required this.end,
    required this.customerName,
    required this.customerEmail,
  });

  final String eventId;
  final String serviceName;
  final DateTime start;
  final DateTime end;
  final String customerName;
  final String customerEmail;

  Map<String, Object?> toJson() => {
    'eventId': eventId,
    'serviceName': serviceName,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'customerName': customerName,
    'customerEmail': customerEmail,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    eventId: json['eventId'] as String,
    serviceName: json['serviceName'] as String,
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    customerName: json['customerName'] as String,
    customerEmail: json['customerEmail'] as String,
  );
}

class AppointmentStore {
  AppointmentStore._();

  static final AppointmentStore instance = AppointmentStore._();
  static const _storageKey = 'anne_nails_appointments';

  Future<List<Appointment>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_storageKey) ?? const [];
    return values
        .map(
          (value) =>
              Appointment.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<void> save(Appointment appointment) async {
    final preferences = await SharedPreferences.getInstance();
    final appointments = await load();
    appointments.add(appointment);
    appointments.sort((a, b) => a.start.compareTo(b.start));
    await preferences.setStringList(
      _storageKey,
      appointments.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
