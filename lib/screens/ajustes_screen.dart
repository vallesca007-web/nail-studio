import 'package:flutter/material.dart';

import '../navigation/tabs.dart';
import '../services/app_session.dart';
import '../services/user_preferences_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _appointmentReminders = true;
  bool _studioNews = false;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preferences = UserPreferencesStore.instance;
      final reminders = await preferences.loadAppointmentReminders();
      final news = await preferences.loadStudioNews();
      if (!mounted) return;
      setState(() {
        _appointmentReminders = reminders;
        _studioNews = news;
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

  Future<void> _updatePreference({
    required bool appointmentReminders,
    required bool enabled,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (appointmentReminders) {
        await UserPreferencesStore.instance.saveAppointmentReminders(enabled);
      } else {
        await UserPreferencesStore.instance.saveStudioNews(enabled);
      }
      if (!mounted) return;
      setState(() {
        if (appointmentReminders) {
          _appointmentReminders = enabled;
        } else {
          _studioNews = enabled;
        }
        _saving = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el ajuste: $error')),
      );
    }
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(
      text: AppSession.instance.displayName,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Editar nombre', style: AppTheme.titleStyle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty || !mounted) return;
    setState(() => AppSession.instance.displayName = trimmedName);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                children: [
                  Text(
                    'PERSONALIZA TU EXPERIENCIA',
                    style: AppTheme.labelStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajustes',
                    style: AppTheme.titleStyle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    title: 'PERFIL',
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.field,
                        foregroundColor: AppTheme.accent,
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(
                        session.displayName,
                        style: AppTheme.titleStyle.copyWith(fontSize: 18),
                      ),
                      subtitle: Text(
                        session.email.isEmpty
                            ? 'Sesión de invitada'
                            : session.email,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Editar nombre',
                        onPressed: _editDisplayName,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    title: 'NOTIFICACIONES',
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accent,
                              ),
                            ),
                          )
                        : _error != null
                        ? ListTile(
                            title: const Text(
                              'No se pudieron cargar los ajustes',
                            ),
                            subtitle: Text(
                              _error!,
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                            trailing: IconButton(
                              tooltip: 'Reintentar',
                              onPressed: _loadPreferences,
                              icon: const Icon(Icons.refresh),
                            ),
                          )
                        : Column(
                            children: [
                              SwitchListTile.adaptive(
                                value: _appointmentReminders,
                                onChanged: _saving
                                    ? null
                                    : (value) => _updatePreference(
                                        appointmentReminders: true,
                                        enabled: value,
                                      ),
                                activeThumbColor: AppTheme.accent,
                                title: const Text('Recordatorios de citas'),
                                subtitle: const Text(
                                  'Preferencia para avisos sobre tus visitas',
                                ),
                              ),
                              const Divider(height: 1, indent: 66),
                              SwitchListTile.adaptive(
                                value: _studioNews,
                                onChanged: _saving
                                    ? null
                                    : (value) => _updatePreference(
                                        appointmentReminders: false,
                                        enabled: value,
                                      ),
                                activeThumbColor: AppTheme.accent,
                                title: const Text('Novedades del estudio'),
                                subtitle: const Text(
                                  'Colecciones, tonos y promociones',
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    title: 'IDIOMA',
                    child: const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.field,
                        foregroundColor: AppTheme.accent,
                        child: Icon(Icons.language),
                      ),
                      title: Text('Español'),
                      subtitle: Text(
                        'Idioma disponible actualmente',
                        style: TextStyle(color: AppTheme.muted, fontSize: 11),
                      ),
                      trailing: Icon(Icons.check, color: AppTheme.accent),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppTheme.softPink.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.accent,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Las preferencias se guardan en este dispositivo. Las notificaciones push todavía no están disponibles.',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onTap: (index) => openTab(context, index),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
            child: Text(
              title,
              style: AppTheme.labelStyle.copyWith(color: AppTheme.muted),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
