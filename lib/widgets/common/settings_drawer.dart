import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../screens/stats_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../services/backup_service.dart';
import '../../screens/profile_screen.dart';
import '../../theme/app_colors_extension.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Drawer(
      backgroundColor: colors.cardBg,
      // ЗМІНЕНО: Огортаємо все в ListView, щоб меню можна було прокручувати (фікс Bottom Overflow)
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- ШАПКА ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // ЗМІНЕНО: Expanded + ellipsis для захисту заголовка від вильоту вправо
                  Expanded(
                    child: Text(
                      'settings'.tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: colors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: colors.textSecondary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 10),

            // КНОПКА ПРОФІЛЮ
            ListTile(
              leading: Icon(Icons.person_outline, color: colors.textMain),
              title: Text(
                'profile'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context);
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
              leading: Icon(Icons.pie_chart_outline, color: colors.textMain),
              title: Text(
                'statistics'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'stats_subtitle'.tr(),
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              },
            ),

            // КНОПКА БЕКАПУ
            ListTile(
              leading: Icon(Icons.backup_outlined, color: colors.textMain),
              title: Text(
                'backup'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'backup_subtitle'.tr(),
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                final safeContext = Navigator.of(context).context;

                Navigator.pop(context);

                showModalBottomSheet(
                  context: safeContext,
                  backgroundColor: colors.cardBg,
                  isScrollControlled: true, // Дозволяємо адаптивну висоту
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) {
                    final sheetColors = Theme.of(
                      ctx,
                    ).extension<AppColorsExtension>()!;

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
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'backup_title'.tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: sheetColors.textMain,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sheetColors.income.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.upload_file,
                                color: sheetColors.income,
                              ),
                            ),
                            title: Text(
                              'export'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sheetColors.textMain,
                              ),
                            ),
                            subtitle: Text(
                              'export_subtitle'.tr(),
                              style: TextStyle(
                                color: sheetColors.textSecondary,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              BackupService.exportData(safeContext);
                            },
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sheetColors.expense.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.settings_backup_restore,
                                color: sheetColors.expense,
                              ),
                            ),
                            title: Text(
                              'import'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sheetColors.textMain,
                              ),
                            ),
                            subtitle: Text(
                              'warning_overwrite'.tr(),
                              style: TextStyle(color: sheetColors.expense),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              BackupService.importData(safeContext);
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

            // КНОПКА ПІДПИСОК
            ListTile(
              leading: Icon(Icons.autorenew, color: colors.textMain),
              title: Text(
                'regular_payments'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context);
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
