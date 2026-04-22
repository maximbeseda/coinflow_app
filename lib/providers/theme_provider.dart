import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';
// 👇 Імпортуємо файл із системними провайдерами
import 'all_providers.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  // 👇 Зручний геттер для доступу до нестатичного StorageService
  StorageService get _storage =>
      StorageService(ref.read(sharedPreferencesProvider));

  @override
  String build() {
    // 👇 Використовуємо екземпляр сервісу
    return _storage.getThemeId();
  }

  void setTheme(String themeId) {
    if (state != themeId) {
      state = themeId;

      // 👇 Зберігаємо в пам'ять через екземпляр
      _storage.saveThemeId(themeId);
    }
  }
}
