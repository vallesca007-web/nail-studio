import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../services/app_session.dart';
import '../services/google_calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'citas_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'servicios_screen.dart';

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
      final appointments = await AppointmentStore.instance.load(
        customerEmail: AppSession.instance.email,
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

  void _navigate(BuildContext context, int index) {
    final page = switch (index) {
      0 => const HomeScreen(),
      1 => ServiciosScreen(),
      2 => const CitasScreen(),
      _ => const PerfilScreen(),
    };
    if (index != 3) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    }
  }

  Future<void> _showAppointments() async {
    final appointments = _appointments;
    if (appointments == null) {
      await _loadAppointments();
      if (!mounted) return;
    }
    if (_appointments == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _AppointmentHistorySheet(
        appointments: _appointments!,
        onBook: () {
          Navigator.pop(context);
          Navigator.push(
            this.context,
            MaterialPageRoute<void>(builder: (_) => const CitasScreen()),
          );
        },
      ),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await GoogleCalendarService.instance.signOut();
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
    final now = DateTime.now();
    final activeAppointments = appointments
        .where((appointment) => appointment.start.isAfter(now))
        .toList();
    final recent = appointments.isEmpty
        ? null
        : appointments.reduce(
            (first, second) =>
                first.start.isAfter(second.start) ? first : second,
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(onProfileTap: () {}),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CUENTA PERSONAL', style: AppTheme.labelStyle),
                            const SizedBox(height: 4),
                            Text(
                              'Mi perfil',
                              style: AppTheme.titleStyle.copyWith(fontSize: 30),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          foregroundColor: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  _accountCard(
                    session: session,
                    activeCount: activeAppointments.length,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ACTIVIDAD RECIENTE',
                          style: AppTheme.labelStyle.copyWith(
                            color: AppTheme.text,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showAppointments,
                        child: const Text('Ver historial'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 23),
                  Text(
                    'PREFERENCIAS Y CUIDADO',
                    style: AppTheme.labelStyle.copyWith(color: AppTheme.text),
                  ),
                  const SizedBox(height: 10),
                  _preferencesCard(),
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
        onTap: (index) => _navigate(context, index),
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
      return _ActionCard(
        icon: Icons.calendar_today_outlined,
        title: _appointmentsError == null
            ? 'Aún no tienes citas'
            : 'No se pudieron cargar las citas',
        subtitle: _appointmentsError == null
            ? 'Tu próxima visita aparecerá aquí.'
            : 'Revisa la conexión e inténtalo de nuevo.',
        onTap: _appointmentsError == null
            ? () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const CitasScreen()),
              )
            : _loadAppointments,
        trailing: _appointmentsError == null
            ? Icons.chevron_right
            : Icons.refresh,
      );
    }

    final date = DateFormat(
      'EEEE, d MMM · HH:mm',
      'es',
    ).format(appointment.start);
    return _ActionCard(
      icon: Icons.spa_outlined,
      title: appointment.serviceName,
      subtitle: '$date hs\n✧  Confirmada',
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

  Widget _preferencesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.text.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _PreferenceRow(
            icon: Icons.calendar_month_outlined,
            title: 'Mis citas',
            subtitle: 'Historial, estados y reagendamiento',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.text),
            onTap: _showAppointments,
          ),
          const Divider(height: 1, indent: 58, color: AppTheme.softPink),
          _PreferenceRow(
            icon: Icons.favorite,
            title: 'Favoritos',
            subtitle: 'Sets guardados, tonos e inspiración',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.text),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 58, color: AppTheme.softPink),
          _PreferenceRow(
            icon: Icons.tune_rounded,
            title: 'Ajustes',
            subtitle: 'Perfil, notificaciones e idioma',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.text),
            onTap: () {},
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

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
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
                    style: AppTheme.titleStyle.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _AppointmentHistorySheet extends StatelessWidget {
  const _AppointmentHistorySheet({
    required this.appointments,
    required this.onBook,
  });

  final List<Appointment> appointments;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final sorted = appointments.toList()
      ..sort((first, second) => second.start.compareTo(first.start));

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
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
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
                                  DateFormat(
                                    'EEEE, d MMMM · HH:mm',
                                    'es',
                                  ).format(appointment.start),
                                  style: const TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            appointment.start.isAfter(DateTime.now())
                                ? Icons.check_circle_outline
                                : Icons.history,
                            color: AppTheme.accent,
                            size: 19,
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
                onPressed: onBook,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Pide tu cita online'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.button,
                  foregroundColor: AppTheme.surface,
                  minimumSize: const Size.fromHeight(52),
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
