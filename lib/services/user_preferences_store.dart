import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesStore {
  UserPreferencesStore._();

  static final UserPreferencesStore instance = UserPreferencesStore._();

  static const _favoritesKey = 'favorite_nail_looks';
  static const _appointmentRemindersKey = 'appointment_reminders_enabled';
  static const _studioNewsKey = 'studio_news_enabled';

  Future<Set<String>> loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_favoritesKey) ?? const <String>[])
        .toSet();
  }

  Future<void> saveFavorites(Set<String> favorites) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      _favoritesKey,
      favorites.toList()..sort(),
    );
    if (!saved) throw StateError('No se pudieron guardar tus favoritos.');
  }

  Future<bool> loadAppointmentReminders() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_appointmentRemindersKey) ?? true;
  }

  Future<void> saveAppointmentReminders(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_appointmentRemindersKey, enabled);
    if (!saved) throw StateError('No se pudo guardar esta preferencia.');
  }

  Future<bool> loadStudioNews() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_studioNewsKey) ?? false;
  }

  Future<void> saveStudioNews(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_studioNewsKey, enabled);
    if (!saved) throw StateError('No se pudo guardar esta preferencia.');
  }
}
