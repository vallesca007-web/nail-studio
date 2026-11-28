import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesStore {
  UserPreferencesStore._();

  static final UserPreferencesStore instance = UserPreferencesStore._();

  static const _favoriteServiceIdsKey = 'favorite_service_ids';
  static const _appointmentRemindersKey = 'appointment_reminders_enabled';
  static const _studioNewsKey = 'studio_news_enabled';

  Future<Set<int>> loadFavoriteServiceIds() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_favoriteServiceIdsKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> saveFavoriteServiceIds(Set<int> favoriteIds) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      _favoriteServiceIdsKey,
      favoriteIds.map((id) => id.toString()).toList()..sort(),
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
