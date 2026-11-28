import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../services/app_session.dart';
import '../services/appointment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'citas_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import 'servicios_screen.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  List<Appointment>? _appointments;
  String? _error;
  bool _loading = true;
  final Set<int> _cancelling = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appointments = await AppointmentService.instance.loadMine(
        token: AppSession.instance.authToken,
      );
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Quieres cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (!_cancelling.add(appointment.id)) return;
    setState(() {});

    try {
      await AppointmentService.instance.cancelAppointment(
        appointmentId: appointment.id,
        token: AppSession.instance.authToken,
      );
      if (!mounted) return;
      final cancelled = appointment.copyWith(estado: 'cancelada');
      setState(() {
        _appointments = _appointments
            ?.map((item) => item.id == cancelled.id ? cancelled : item)
            .toList();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cita cancelada.')));
    } on AppointmentServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      _cancelling.remove(appointment.id);
      if (mounted) setState(() {});
    }
  }

  void _navigate(int index) {
    final page = switch (index) {
      0 => const HomeScreen(),
      1 => const ServiciosScreen(),
      2 => const CitasScreen(),
      _ => const PerfilScreen(),
    };
    if (index != 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _appointments ?? const <Appointment>[];
    final upcoming = appointments
        .where(
          (appointment) =>
              (appointment.start?.isAfter(DateTime.now()) ?? false) &&
              ['pendiente', 'agendada'].contains(appointment.estado),
        )
        .toList();
    final history = appointments
        .where((appointment) => !upcoming.contains(appointment))
        .toList()
        .reversed
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              onProfileTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const PerfilScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                children: [
                  Text('TU AGENDA', style: AppTheme.labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Mis citas',
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Consulta tus próximas visitas y el historial del estudio.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  else if (_error != null)
                    _MessageCard(
                      icon: Icons.cloud_off_outlined,
                      title: AppSession.instance.email.isEmpty
                          ? 'Inicia sesión para ver tus citas'
                          : 'No pudimos cargar tus citas',
                      message: _error!,
                      actionLabel: AppSession.instance.email.isEmpty
                          ? 'Volver al perfil'
                          : 'Intentar de nuevo',
                      onAction: AppSession.instance.email.isEmpty
                          ? () => Navigator.pop(context)
                          : _loadAppointments,
                    )
                  else if (appointments.isEmpty)
                    _MessageCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Aún no tienes citas',
                      message: 'Cuando reserves una visita, aquí encontrarás su fecha y estado.',
                      actionLabel: 'Agendar una cita',
                      onAction: _bookAppointment,
                    )
                  else ...[
                    _sectionTitle('PRÓXIMAS VISITAS', upcoming.length),
                    const SizedBox(height: 10),
                    if (upcoming.isEmpty)
                      const _EmptySection(
                        text: 'No tienes próximas visitas agendadas.',
                      )
                    else
                      ...upcoming.map(
                        (appointment) => _AppointmentCard(
                          appointment: appointment,
                          isUpcoming: true,
                          cancelling: _cancelling.contains(appointment.id),
                          onCancel: () => _cancelAppointment(appointment),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _sectionTitle('HISTORIAL', history.length),
                    const SizedBox(height: 10),
                    if (history.isEmpty)
                      const _EmptySection(
                        text: 'Tus visitas anteriores aparecerán aquí.',
                      )
                    else
                      ...history.map(
                        (appointment) => _AppointmentCard(
                          appointment: appointment,
                          isUpcoming: false,
                        ),
                      ),
                  ],
                  if (!_loading &&
                      _error == null &&
                      appointments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _bookAppointment,
                      icon: const Icon(Icons.add),
                      label: const Text('Agendar otra cita'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes cancelar una cita próxima desde su tarjeta. Para cambiar el horario, contacta directamente con el estudio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 3, onTap: _navigate),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTheme.labelStyle.copyWith(color: AppTheme.text),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _bookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CitasScreen()),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isUpcoming,
    this.cancelling = false,
    this.onCancel,
  });

  final Appointment appointment;
  final bool isUpcoming;
  final bool cancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final statusColor = switch (status.toLowerCase()) {
      'agendada' || 'confirmada' => const Color(0xFF3F795B),
      'cancelada' || 'cancelado' => AppTheme.muted,
      'pendiente' => AppTheme.accent,
      _ => AppTheme.muted,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.text.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.field,
            foregroundColor: AppTheme.accent,
            child: Icon(
              isUpcoming ? Icons.spa_outlined : Icons.history_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.serviceName,
                  style: AppTheme.titleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  appointment.start == null
                      ? 'Fecha por confirmar'
                      : DateFormat(
                          'EEEE, d MMMM · HH:mm',
                          'es',
                        ).format(appointment.start!),
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isUpcoming && onCancel != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: cancelling ? null : onCancel,
                    icon: cancelling
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: Text(cancelling ? 'Cancelando…' : 'Cancelar cita'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Registrada';
    return status[0].toUpperCase() + status.substring(1);
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.softPink,
            foregroundColor: AppTheme.accent,
            child: Icon(icon),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.titleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.button,
              foregroundColor: AppTheme.surface,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.muted, fontSize: 12),
      ),
    );
  }
}
