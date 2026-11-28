import 'package:anne_nail_studio/services/user_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and reloads favorite designs', () async {
    final store = UserPreferencesStore.instance;

    await store.saveFavorites({'rose-french', 'soft-nude'});

    expect(await store.loadFavorites(), {'rose-french', 'soft-nude'});
  });

  test('saves notification preferences independently', () async {
    final store = UserPreferencesStore.instance;

    await store.saveAppointmentReminders(false);
    await store.saveStudioNews(true);

    expect(await store.loadAppointmentReminders(), isFalse);
    expect(await store.loadStudioNews(), isTrue);
  });
}
