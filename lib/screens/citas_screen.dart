import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../services/appointment_service.dart';
import '../services/app_session.dart';
import '../services/google_sign_in_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/pill_button.dart';
import 'confirmacion_cita_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import 'servicios_screen.dart';

DateTime _initialBookingDay() {
  final today = DateUtils.dateOnly(DateTime.now());
  return today.weekday == DateTime.sunday
      ? today.add(const Duration(days: 1))
      : today;
}

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  static const _serviceName = 'Manicura Rusa & Esmaltado';
  static const _serviceDuration = AppConfig.signatureServiceDuration;

  DateTime _selectedDay = _initialBookingDay();
  DateTime? _selectedSlot;
  List<DateTime> _availableSlots = [];
  bool _loadingSlots = true;
  bool _booking = false;
  String? _errorMessage;
  int _availabilityRequest = 0;
  double _servicePrice = AppConfig.signatureServicePrice;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final request = ++_availabilityRequest;
    final day = _selectedDay;
    setState(() {
      _loadingSlots = true;
      _errorMessage = null;
      _selectedSlot = null;
    });
    try {
      final availability = await AppointmentService.instance.getAvailability(
        date: day,
        serviceId: AppConfig.signatureServiceId,
      );
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        _availableSlots = availability.all;
        if (availability.price != null) _servicePrice = availability.price!;
        _loadingSlots = false;
      });
    } on AppointmentServiceException catch (error) {
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        _errorMessage = error.message;
        _loadingSlots = false;
      });
    }
  }

  void _selectDay(DateTime day) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (day.isBefore(today) || day.weekday == DateTime.sunday) {
      return;
    }
    setState(() => _selectedDay = day);
    _loadSlots();
  }

  DateTime _weekStart(DateTime date) =>
      date.subtract(Duration(days: date.weekday - DateTime.monday));

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _sameTime(DateTime first, DateTime second) =>
      _sameDay(first, second) &&
      first.hour == second.hour &&
      first.minute == second.minute;

  void _changeMonth(int offset) {
    final nextMonth = DateTime(_selectedDay.year, _selectedDay.month + offset);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final day = DateTime(
      nextMonth.year,
      nextMonth.month,
      _selectedDay.day.clamp(1, lastDay),
    );
    final today = DateUtils.dateOnly(DateTime.now());
    _selectDay(day.isBefore(today) ? today : day);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      initialDate: _selectedDay.isBefore(today) ? today : _selectedDay,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      selectableDayPredicate: (day) => day.weekday != DateTime.sunday,
    );
    if (chosen != null) _selectDay(chosen);
  }

  Future<void> _confirmAppointment() async {
    final slot = _selectedSlot;
    if (slot == null || _booking) return;
    final day = _selectedDay;
    setState(() {
      _booking = true;
      _errorMessage = null;
    });
    try {
      final idToken = await GoogleSignInService.instance.signInAndGetIdToken();
      final session = AppSession.instance;
      final appointment = await AppointmentService.instance.createAppointment(
        serviceId: AppConfig.signatureServiceId,
        date: day,
        time: slot,
        customerName: session.displayName,
        idToken: idToken,
        customerPhone: _phoneController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ConfirmacionCitaScreen(appointment: appointment),
        ),
      );
    } on GoogleSignInCancelledException {
      if (!mounted) return;
      setState(() {
        _booking = false;
        _errorMessage = 'Inicia sesión con Google para confirmar tu cita.';
      });
    } on GoogleSignInServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _booking = false;
        _errorMessage = error.message;
      });
    } on AppointmentServiceException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        setState(() {
          _booking = false;
          _selectedSlot = null;
        });
        await _loadSlots();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ese horario acaba de ocuparse. Actualizamos la disponibilidad.',
              ),
            ),
          );
        }
        return;
      }
      setState(() {
        _booking = false;
        _errorMessage = error.message;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _booking = false;
        _errorMessage = 'No pudimos confirmar la cita. Inténtalo nuevamente.';
      });
    }
  }

  void _navigate(int index) {
    final page = switch (index) {
      0 => const HomeScreen(),
      1 => ServiciosScreen(),
      3 => const PerfilScreen(),
      _ => const CitasScreen(),
    };
    if (index != 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM yyyy', 'es').format(_selectedDay);
    final weekStart = _weekStart(_selectedDay);
    final today = DateUtils.dateOnly(DateTime.now());
    final morning = _availableSlots.where((slot) => slot.hour < 12).toList();
    final afternoon = _availableSlots.where((slot) => slot.hour >= 12).toList();
    final canConfirm = _selectedSlot != null && !_booking && !_loadingSlots;

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
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SecondaryPill(
                            label: 'Atrás',
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Agendar cita',
                          textAlign: TextAlign.center,
                          style: AppTheme.titleStyle.copyWith(fontSize: 22),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.surface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  _serviceCard(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      hintText: 'Ej. 656 123 4567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 23),
                  _sectionHeader('PASO 01', 'Selecciona Fecha'),
                  const SizedBox(height: 12),
                  _monthSelector(month, today),
                  const SizedBox(height: 12),
                  _dateStrip(weekStart, today),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: _sectionHeader('PASO 02', 'Horario Disponible'),
                      ),
                      Text(
                        'Hora del estudio',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _errorCard(),
                  ],
                  if (_loadingSlots)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    const SizedBox.shrink()
                  else if (_availableSlots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No hay horarios disponibles para esta fecha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 14),
                    _timeGroup('MAÑANA', Icons.wb_sunny_outlined, morning),
                    const SizedBox(height: 15),
                    _timeGroup('TARDE', Icons.nights_stay_outlined, afternoon),
                  ],
                  const SizedBox(height: 22),
                  _specialistCard(),
                  const SizedBox(height: 18),
                  PillButton(
                    label: _booking ? 'Confirmando…' : 'Confirmar cita',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: canConfirm ? _confirmAppointment : null,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cancelación gratuita hasta 24 horas antes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 2, onTap: _navigate),
    );
  }

  Widget _serviceCard() {
    final price = NumberFormat.currency(name: AppConfig.currencyCode)
        .format(_servicePrice);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.text.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=240&q=80',
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.softPink,
                child: Icon(Icons.spa_outlined, color: AppTheme.accent),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIGNATURE', style: AppTheme.labelStyle),
                const SizedBox(height: 4),
                Text(
                  _serviceName,
                  style: AppTheme.titleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_serviceDuration.inMinutes} min  ·  $price',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String step, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(step, style: AppTheme.labelStyle),
        const SizedBox(height: 3),
        Text(title, style: AppTheme.titleStyle.copyWith(fontSize: 20)),
      ],
    );
  }

  Widget _monthSelector(String month, DateTime today) {
    final firstOfMonth = DateTime(_selectedDay.year, _selectedDay.month);
    final firstOfCurrentMonth = DateTime(today.year, today.month);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: firstOfMonth.isAfter(firstOfCurrentMonth)
              ? () => _changeMonth(-1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          month.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.text,
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _dateStrip(DateTime weekStart, DateTime today) {
    return Row(
      children: List.generate(7, (index) {
        final day = weekStart.add(Duration(days: index));
        final selected = _sameDay(day, _selectedDay);
        final disabled = day.isBefore(today) || day.weekday == DateTime.sunday;
        final weekday = DateFormat('EEE', 'es').format(day);
        return Expanded(
          child: GestureDetector(
            onTap: disabled ? null : () => _selectDay(day),
            child: Opacity(
              opacity: disabled ? 0.38 : 1,
              child: Column(
                children: [
                  Text(
                    weekday.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: 40,
                    height: 54,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.button : AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: selected
                          ? Border.all(color: AppTheme.heroPink, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: selected ? AppTheme.surface : AppTheme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.heroPink
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _timeGroup(String title, IconData icon, List<DateTime> times) {
    if (times.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.accent),
            const SizedBox(width: 7),
            Text(
              title,
              style: AppTheme.labelStyle.copyWith(
                color: AppTheme.text,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        GridView.builder(
          itemCount: times.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 9,
            mainAxisSpacing: 8,
            mainAxisExtent: 42,
          ),
          itemBuilder: (context, index) {
            final time = times[index];
            final selected =
                _selectedSlot != null && _sameTime(_selectedSlot!, time);
            return OutlinedButton(
              onPressed: () => setState(() => _selectedSlot = time),
              style: OutlinedButton.styleFrom(
                foregroundColor: selected ? AppTheme.surface : AppTheme.text,
                backgroundColor: selected ? AppTheme.button : AppTheme.surface,
                disabledForegroundColor: AppTheme.disabled,
                side: BorderSide(
                  color: selected ? AppTheme.button : AppTheme.softPink,
                ),
                shape: const StadiumBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                DateFormat('HH:mm').format(time),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _specialistCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.softPink,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: AppTheme.surface,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=200&q=80',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESPECIALISTA', style: AppTheme.labelStyle),
                const SizedBox(height: 3),
                Text(
                  'Anne Marie',
                  style: AppTheme.titleStyle.copyWith(fontSize: 17),
                ),
                const Text(
                  'Master Nail Artist',
                  style: TextStyle(color: AppTheme.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: AppTheme.accent, size: 21),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.softPink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.text, fontSize: 11),
            ),
          ),
          TextButton(onPressed: _loadSlots, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
