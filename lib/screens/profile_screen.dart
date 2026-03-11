import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_currency.dart';
import '../theme/app_colors_extension.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: colors.textMain),
        title: Text(
          'profile'.tr(),
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.bgGradientStart, colors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 1. АВТОМАТИЗОВАНИЙ ВИБІР ТЕМИ
                    _buildSettingsRow(
                      colors: colors,
                      icon: Icons.palette_outlined,
                      title: 'interface_theme'.tr(),
                      dropdownValue: themeProvider.currentThemeId,
                      items: AppTheme.allThemes.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          alignment: Alignment.centerRight,
                          child: Text(
                            entry.value.tr(),
                            style: TextStyle(color: colors.textMain),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          val != null ? themeProvider.setTheme(val) : null,
                    ),

                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: colors.textSecondary.withValues(alpha: 0.1),
                    ),

                    // 2. АВТОМАТИЗОВАНИЙ ВИБІР МОВИ
                    _buildSettingsRow(
                      colors: colors,
                      icon: Icons.language_outlined,
                      title: 'language'.tr(),
                      dropdownValue: context.locale.languageCode,
                      items: context.supportedLocales.map((locale) {
                        return DropdownMenuItem(
                          value: locale.languageCode,
                          alignment: Alignment.centerRight,
                          child: Text(
                            AppConstants.languages[locale.languageCode] ??
                                locale.languageCode.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          val != null ? context.setLocale(Locale(val)) : null,
                    ),

                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: colors.textSecondary.withValues(alpha: 0.1),
                    ),

                    // 3. ВИБІР БАЗОВОЇ ВАЛЮТИ
                    _buildSettingsRow(
                      colors: colors,
                      icon: Icons.monetization_on_outlined,
                      title: 'base_currency'.tr(),
                      dropdownValue: settingsProvider.baseCurrency,
                      items: AppCurrency.supportedCurrencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency.code,
                          alignment: Alignment.centerRight,
                          child: Text(
                            "${currency.code} (${currency.symbol})",
                            style: TextStyle(
                              color: colors.income,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => val != null
                          ? settingsProvider.setBaseCurrency(val)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ДОДАНО: Універсальний метод-шаблон для пунктів меню.
  // Гарантує 100% ідентичний дизайн для всіх рядків.
  Widget _buildSettingsRow({
    required AppColorsExtension colors,
    required IconData icon,
    required String title,
    required String dropdownValue,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: colors.textMain),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textMain,
          fontWeight: FontWeight.w600,
          fontSize: 16, // Строго фіксований однаковий розмір
        ),
        maxLines: 2, // Дозволяємо перенесення довгого слова на 2 рядок
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 115, // Зменшили зі 130, щоб дати тексту більше місця
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: dropdownValue,
            dropdownColor: colors.cardBg,
            borderRadius: BorderRadius.circular(20),
            alignment: Alignment.centerRight,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: colors.textSecondary,
              size: 20,
            ),
            onChanged: onChanged,
            items: items,
          ),
        ),
      ),
    );
  }
}
