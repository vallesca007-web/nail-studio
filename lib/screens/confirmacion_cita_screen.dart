import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';
import 'home_screen.dart';

class ConfirmacionCitaScreen extends StatefulWidget {
  const ConfirmacionCitaScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<ConfirmacionCitaScreen> createState() => _ConfirmacionCitaScreenState();
}

class _ConfirmacionCitaScreenState extends State<ConfirmacionCitaScreen> {
  bool _openingCalendar = false;

  // La API crea el evento en Google Calendar cuando está configurado y devuelve
  // su enlace. Si no lo está, se abre el formulario de Google Calendar ya
  // lleno con los datos de la cita.
  Uri? get _calendarUri {
    final eventUrl = widget.appointment.eventUrl;
    if (eventUrl != null) return Uri.parse(eventUrl);

    final appointment = widget.appointment;
    final start = appointment.start;
    final end = appointment.end;
    if (start == null || end == null) return null;

    final stamp = DateFormat("yyyyMMdd'T'HHmmss");
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': '${appointment.serviceName} · ${AppConfig.studioName}',
      'dates': '${stamp.format(start)}/${stamp.format(end)}',
      'details': 'Código de reserva ${appointment.reservationCode}',
      'location': AppConfig.studioName,
    });
  }

  Future<void> _openCalendar() async {
    final uri = _calendarUri;
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos leer la fecha de la cita. Contacta al estudio.',
          ),
        ),
      );
      return;
    }
    setState(() => _openingCalendar = true);
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw Exception('No se pudo abrir Google Calendar.');
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pudimos abrir el calendario: $error')),
      );
    } finally {
      if (mounted) setState(() => _openingCalendar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final start = appointment.start;
    final end = appointment.end;
    final date = start == null
        ? 'Fecha por confirmar'
        : DateFormat('EEEE d MMMM yyyy', 'es').format(start);
    final time = start == null || end == null
        ? 'Hora por confirmar'
        : '${DateFormat('HH:mm').format(start)} – '
              '${DateFormat('HH:mm').format(end)}';
    final code = appointment.reservationCode;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppTheme.softPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppTheme.accent,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '¡Cita confirmada!',
                    textAlign: TextAlign.center,
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu momento de cuidado ya está reservado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(21),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.text.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DETALLES DE RESERVA', style: AppTheme.labelStyle),
                        const SizedBox(height: 15),
                        _DetailRow(label: 'CÓDIGO', value: code),
                        _DetailRow(
                          label: 'SERVICIO',
                          value: appointment.serviceName,
                        ),
                        _DetailRow(label: 'SALÓN', value: AppConfig.studioName),
                        _DetailRow(label: 'FECHA', value: date),
                        _DetailRow(label: 'HORA', value: time),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (start == null)
                    const Text(
                      'No pudimos leer la fecha de la cita. Escríbenos para '
                      'confirmarla.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    )
                  else
                    const Text(
                      'Recibirás los detalles por correo. Para coordinar por WhatsApp, '
                      'contacta directamente con el estudio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 22),
                  PillButton(
                    label: _openingCalendar
                        ? 'Abriendo calendario…'
                        : 'Agregar al calendario',
                    icon: Icons.calendar_month_outlined,
                    onPressed: _openingCalendar ? null : _openCalendar,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeScreen(),
                      ),
                      (_) => false,
                    ),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
