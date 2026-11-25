import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../navigation/tabs.dart';
import '../services/app_session.dart';
import '../services/appointment_service.dart';
import '../services/google_sign_in_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/preferences_section.dart';
import 'ajustes_screen.dart';
import 'citas_screen.dart';
import 'favoritos_screen.dart';
import 'login_screen.dart';
import 'mis_citas_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  List<Appointment>? _appointments;
  String? _appointmentsError;
  bool _loadingAppointments = true;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loadingAppointments = true;
      _appointmentsError = null;
    });
    try {
      final appointments = await AppointmentService.instance.loadMine(
        token: AppSession.instance.authToken,
      );
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _loadingAppointments = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _appointmentsError = error.toString();
        _loadingAppointments = false;
      });
    }
  }

  Future<void> _showAppointments() async {
    if (_appointments == null) await _loadAppointments();
    if (!mounted || _appointments == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => _AppointmentHistorySheet(
        appointments: _appointments!,
        onCancel: _cancelAppointment,
        onBook: () {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CitasScreen()),
          );
        },
      ),
    );
  }

  Future<void> _openAppointmentsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const MisCitasScreen()),
    );
    if (mounted) await _loadAppointments();
  }

  void _showFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const FavoritosScreen()),
    );
  }

  Future<void> _showSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AjustesScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<Appointment?> _cancelAppointment(Appointment appointment) async {
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
    if (!mounted) return null;
    if (confirmed != true) return null;

    try {
      await AppointmentService.instance.cancelAppointment(
        appointmentId: appointment.id,
        token: AppSession.instance.authToken,
      );
      if (!mounted) return null;
      final cancelled = appointment.copyWith(estado: 'cancelada');
      setState(() {
        _appointments = _appointments
            ?.map((item) => item.id == cancelled.id ? cancelled : item)
            .toList();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cita cancelada.')));
      return cancelled;
    } on AppointmentServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return null;
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await GoogleSignInService.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar la sesión: $error')),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final appointments = _appointments ?? const <Appointment>[];
    final activeCount = appointments
        .where(
          (appointment) =>
              (appointment.start?.isAfter(DateTime.now()) ?? false) &&
              ['pendiente', 'agendada'].contains(appointment.estado),
        )
        .length;
    // loadMine ordena de más antigua a más reciente.
    final recent = appointments.isEmpty ? null : appointments.last;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                children: [
                  Text('CUENTA PERSONAL', style: AppTheme.labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Mi perfil',
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 17),
                  _accountCard(session: session, activeCount: activeCount),
                  const SizedBox(height: 24),
                  Text(
                    'ACTIVIDAD RECIENTE',
                    style: AppTheme.labelStyle.copyWith(color: AppTheme.text),
                  ),
                  const SizedBox(height: 10),
                  _recentAppointment(recent),
                  if (_appointmentsError != null) ...[
                    const SizedBox(height: 10),
                    _loadErrorCard(),
                  ],
                  if (_loadingAppointments)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(
                        color: AppTheme.accent,
                        backgroundColor: AppTheme.softPink,
                      ),
                    ),
                  const SizedBox(height: 24),
                  PreferencesSection(
                    onAppointmentsTap: _openAppointmentsScreen,
                    onFavoritesTap: _showFavorites,
                    onSettingsTap: _showSettings,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _signingOut ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(
                      _signingOut ? 'Cerrando sesión…' : 'Cerrar sesión',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.text,
                      backgroundColor: AppTheme.surface,
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Anne Nails • Versión 1.0',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        onTap: (index) => openTab(context, index),
      ),
    );
  }

  Widget _accountCard({required AppSession session, required int activeCount}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, AppTheme.softPink],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.text.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.heroPink, width: 3),
            ),
            child: CircleAvatar(
              backgroundColor: AppTheme.softPink,
              backgroundImage: session.photoUrl == null
                  ? null
                  : NetworkImage(session.photoUrl!),
              child: session.photoUrl == null
                  ? const Icon(
                      Icons.person_outline,
                      color: AppTheme.accent,
                      size: 42,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  session.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleStyle.copyWith(fontSize: 24),
                ),
              ),
              if (session.isGoogleUser) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: AppTheme.accent, size: 19),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            session.email.isEmpty ? 'Sesión de invitada' : session.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppTheme.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: _showAppointments,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Column(
                  children: [
                    Text(
                      'CITAS ACTIVAS',
                      style: AppTheme.labelStyle.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _appointmentsError == null ? '$activeCount' : '—',
                      style: AppTheme.titleStyle.copyWith(fontSize: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentAppointment(Appointment? appointment) {
    if (appointment == null) {
      final hasError = _appointmentsError != null;
      return _ActionCard(
        icon: Icons.calendar_today_outlined,
        title: hasError
            ? 'No se pudieron cargar las citas'
            : 'Aún no tienes citas',
        subtitle: hasError
            ? 'Revisa la conexión e inténtalo de nuevo.'
            : 'Tu próxima visita aparecerá aquí.',
        onTap: hasError
            ? _loadAppointments
            : () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const CitasScreen()),
              ),
        trailing: hasError ? Icons.refresh : Icons.chevron_right,
      );
    }

    final start = appointment.start;
    final date = start == null
        ? 'Fecha por confirmar'
        : DateFormat('EEEE, d MMM · HH:mm', 'es').format(start);
    return _ActionCard(
      icon: Icons.spa_outlined,
      title: appointment.serviceName,
      subtitle: '$date hs\nEstado: ${appointment.estado}',
      onTap: _showAppointments,
      trailing: Icons.chevron_right,
    );
  }

  Widget _loadErrorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.softPink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'No pudimos cargar tus citas guardadas.',
              style: TextStyle(color: AppTheme.text, fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: _loadAppointments,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(27),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.field,
                foregroundColor: AppTheme.accent,
                child: Icon(icon),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(trailing, color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentHistorySheet extends StatefulWidget {
  const _AppointmentHistorySheet({
    required this.appointments,
    required this.onCancel,
    required this.onBook,
  });

  final List<Appointment> appointments;
  final Future<Appointment?> Function(Appointment) onCancel;
  final VoidCallback onBook;

  @override
  State<_AppointmentHistorySheet> createState() =>
      _AppointmentHistorySheetState();
}

class _AppointmentHistorySheetState extends State<_AppointmentHistorySheet> {
  late List<Appointment> _appointments;
  final Set<int> _cancelling = {};

  @override
  void initState() {
    super.initState();
    _appointments = List.of(widget.appointments);
  }

  Future<void> _cancel(Appointment appointment) async {
    if (!_cancelling.add(appointment.id)) return;
    setState(() {});
    try {
      final updated = await widget.onCancel(appointment);
      if (updated != null && mounted) {
        setState(() {
          _appointments = _appointments
              .map((item) => item.id == updated.id ? updated : item)
              .toList();
        });
      }
    } finally {
      _cancelling.remove(appointment.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _appointments.reversed.toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.disabled,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mis citas',
              style: AppTheme.titleStyle.copyWith(fontSize: 25),
            ),
            const SizedBox(height: 14),
            if (sorted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Aún no hay citas guardadas. Agenda tu primera visita.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final appointment = sorted[index];
                    final canCancel =
                        [
                          'pendiente',
                          'agendada',
                        ].contains(appointment.estado) &&
                        (appointment.start?.isAfter(DateTime.now()) ?? false);
                    final cancelling = _cancelling.contains(appointment.id);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppTheme.softPink,
                                foregroundColor: AppTheme.accent,
                                child: Icon(Icons.spa_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appointment.serviceName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      appointment.start == null
                                          ? 'Fecha por confirmar'
                                          : DateFormat(
                                              'EEEE, d MMMM · HH:mm',
                                              'es',
                                            ).format(appointment.start!),
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Estado: ${appointment.estado}',
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                appointment.estado == 'cancelada'
                                    ? Icons.cancel_outlined
                                    : appointment.start?.isAfter(
                                            DateTime.now(),
                                          ) ??
                                          false
                                    ? Icons.check_circle_outline
                                    : Icons.history,
                                color: appointment.estado == 'cancelada'
                                    ? AppTheme.muted
                                    : AppTheme.accent,
                                size: 19,
                              ),
                            ],
                          ),
                          if (canCancel)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: cancelling
                                    ? null
                                    : () => _cancel(appointment),
                                icon: cancelling
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.cancel_outlined),
                                label: Text(
                                  cancelling ? 'Cancelando…' : 'Cancelar cita',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onBook,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Pide tu cita online'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.button,
                  foregroundColor: AppTheme.surface,
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
