import 'package:flutter/material.dart';
import '../services/storage_service.dart'; // Імпортуємо наш сервіс

class ThemeProvider extends ChangeNotifier {
  String _currentThemeId = 'light';

  String get currentThemeId => _currentThemeId;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    // Використовуємо StorageService замість прямого звернення до Hive
    _currentThemeId = StorageService.getThemeId();
    notifyListeners();
  }

  void setTheme(String themeId) {
    if (_currentThemeId != themeId) {
      _currentThemeId = themeId;
      StorageService.saveThemeId(themeId); // Зберігаємо через сервіс
      notifyListeners();
    }
  }
}
