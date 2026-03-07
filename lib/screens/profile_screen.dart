import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors_extension.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      // Робимо сам Scaffold прозорим, щоб бачити градієнт підкладки
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
        // ФІКС: Встановлюємо градієнтний фон як на інших екранах
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
              // ЄДИНИЙ БЛОК НАЛАШТУВАНЬ
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
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.palette_outlined,
                        color: colors.textMain,
                      ),
                      title: Text(
                        'interface_theme'.tr(),
                        style: TextStyle(
                          color: colors.textMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: SizedBox(
                        width: 130,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: themeProvider.currentThemeId,
                            dropdownColor: colors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            alignment: Alignment.centerRight,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: colors.textSecondary,
                              size: 20,
                            ),
                            onChanged: (val) => val != null
                                ? themeProvider.setTheme(val)
                                : null,
                            // Динамічний список з AppTheme
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
                          ),
                        ),
                      ),
                    ),

                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: colors.textSecondary.withValues(alpha: 0.1),
                    ),

                    // 2. АВТОМАТИЗОВАНИЙ ВИБІР МОВИ
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.language_outlined,
                        color: colors.textMain,
                      ),
                      title: Text(
                        'language'.tr(),
                        style: TextStyle(
                          color: colors.textMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: SizedBox(
                        width: 130,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: context.locale.languageCode,
                            dropdownColor: colors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            alignment: Alignment.centerRight,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: colors.textSecondary,
                              size: 20,
                            ),
                            onChanged: (val) => val != null
                                ? context.setLocale(Locale(val))
                                : null,
                            // Динамічний список з AppConstants
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
                          ),
                        ),
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
  }
}
