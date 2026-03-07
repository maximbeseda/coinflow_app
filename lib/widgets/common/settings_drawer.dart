import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/finance_provider.dart';
import '../../screens/stats_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../services/backup_service.dart';
import '../../screens/profile_screen.dart';
import '../../theme/app_colors_extension.dart'; // ДОДАНО: Імпорт теми

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // ДОДАНО: Отримуємо кольори теми
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Drawer(
      backgroundColor: colors.cardBg, // ЗМІНЕНО: Був жорсткий Color(0xFFF5F5F7)
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Text(
                    'settings'.tr(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textMain, // ЗМІНЕНО
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.iconBg, // ЗМІНЕНО: Фон кнопки закриття
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: colors.textMain, // ЗМІНЕНО
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: colors.textSecondary.withValues(
                alpha: 0.2,
              ), // ЗМІНЕНО: Адаптивний розділювач
            ),
            const SizedBox(height: 10),

            // КНОПКА ПРОФІЛЮ
            ListTile(
              leading: Icon(
                Icons.person_outline,
                color: colors.textMain,
              ), // ЗМІНЕНО
              title: Text(
                'profile'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textMain, // ЗМІНЕНО
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Закриваємо меню
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),

            // КНОПКА СТАТИСТИКИ
            ListTile(
              leading: Icon(
                Icons.pie_chart_outline,
                color: colors.textMain, // ЗМІНЕНО
              ),
              title: Text(
                'statistics'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textMain, // ЗМІНЕНО
                ),
              ),
              subtitle: Text(
                'stats_subtitle'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary, // ЗМІНЕНО
                ),
              ),
              onTap: () async {
                // 1. Закриваємо меню
                Navigator.pop(context);

                // 2. Відкриваємо екран статистики і чекаємо, поки користувач з нього вийде
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              },
            ),

            // КНОПКА БЕКАПУ
            ListTile(
              leading: Icon(
                Icons.backup_outlined,
                color: colors.textMain,
              ), // ЗМІНЕНО
              title: Text(
                'backup'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textMain, // ЗМІНЕНО
                ),
              ),
              subtitle: Text(
                'backup_subtitle'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary, // ЗМІНЕНО
                ),
              ),
              onTap: () {
                // МАГІЯ: Отримуємо безпечний контекст Навігатора та Провайдер
                // ДО того, як закриємо бокове меню. Цей контекст ніколи не "вмирає".
                final safeContext = Navigator.of(context).context;
                final provider = safeContext.read<FinanceProvider>();

                // Тепер безпечно закриваємо бокове меню
                Navigator.pop(context);

                showModalBottomSheet(
                  context: safeContext, // Використовуємо живий контекст
                  backgroundColor: colors.cardBg, // ЗМІНЕНО: Фон панелі бекапу
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) {
                    final sheetColors = Theme.of(ctx)
                        .extension<
                          AppColorsExtension
                        >()!; // Кольори всередині діалогу

                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: sheetColors.textSecondary.withValues(
                                alpha: 0.2,
                              ), // ЗМІНЕНО: Повзунок
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'backup_title'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: sheetColors.textMain, // ЗМІНЕНО
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sheetColors.income.withValues(
                                alpha: 0.1,
                              ), // ЗМІНЕНО: Фон як у доходів
                              child: Icon(
                                Icons.upload_file,
                                color: sheetColors.income,
                              ), // ЗМІНЕНО
                            ),
                            title: Text(
                              'export'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sheetColors.textMain, // ЗМІНЕНО
                              ),
                            ),
                            subtitle: Text(
                              'export_subtitle'.tr(),
                              style: TextStyle(
                                color: sheetColors.textSecondary,
                              ), // ЗМІНЕНО
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              // Використовуємо живі provider та safeContext
                              BackupService.exportData(provider, safeContext);
                            },
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sheetColors.expense.withValues(
                                alpha: 0.1,
                              ), // ЗМІНЕНО: Фон як у витрат
                              child: Icon(
                                Icons.settings_backup_restore,
                                color: sheetColors.expense, // ЗМІНЕНО
                              ),
                            ),
                            title: Text(
                              'import'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sheetColors.textMain, // ЗМІНЕНО
                              ),
                            ),
                            subtitle: Text(
                              'warning_overwrite'.tr(),
                              style: TextStyle(
                                color: sheetColors.expense,
                              ), // ЗМІНЕНО
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              // Використовуємо живі provider та safeContext
                              BackupService.importData(provider, safeContext);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // ДОДАЄМО КНОПКУ ПІДПИСОК
            ListTile(
              leading: Icon(Icons.autorenew, color: colors.textMain), // ЗМІНЕНО
              title: Text(
                'regular_payments'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textMain, // ЗМІНЕНО
                ),
              ),
              onTap: () {
                // Спочатку закриваємо бокове меню
                Navigator.pop(context);
                // Потім відкриваємо наш новий екран
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
