import 'package:anne_nail_studio/models/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the appointment history response returned by the API', () {
    final appointment = Appointment.fromJson({
      'eventId': 'event-1',
      'serviceName': 'Manicura',
      'start': '2026-11-24T16:00:00.000Z',
      'end': '2026-11-24T17:00:00.000Z',
      'status': 'agendada',
    });

    expect(appointment.customerName, isEmpty);
    expect(appointment.customerEmail, isEmpty);
    expect(appointment.status, 'agendada');
    expect(appointment.serviceName, 'Manicura');
  });
}
