import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';

// Цей рядок обов'язковий для генерації коду
part 'theme_provider.g.dart';

// keepAlive: true означає, що цей стан буде жити завжди,
// навіть якщо на екрані зараз немає жодного віджета, який його слухає.
// Для теми додатку це обов'язково.
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  // Метод build() замінює конструктор.
  // Те, що він повертає, стає початковим станом (state).
  @override
  String build() {
    // Відразу завантажуємо тему з нашого сервісу
    return StorageService.getThemeId();
  }

  // Метод для зміни теми
  void setTheme(String themeId) {
    if (state != themeId) {
      // Присвоєння нового значення змінній `state` АВТОМАТИЧНО
      // перемальовує всі віджети, які слухають цей провайдер.
      // Більше ніяких notifyListeners()!
      state = themeId;

      // Зберігаємо в пам'ять
      StorageService.saveThemeId(themeId);
    }
  }
}
