import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ДОДАНО
import 'package:easy_localization/easy_localization.dart';
import '../../screens/stats_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../services/backup_service.dart';
import '../../screens/profile_screen.dart';
import '../../theme/app_colors_extension.dart';
import '../../providers/subscription_provider.dart'; // ДОДАНО

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // ДОДАНО: Слухаємо провайдер, щоб знати, чи є відкладені платежі
    final hasPendingSubscriptions = context
        .watch<SubscriptionProvider>()
        .hasPendingPayments;

    return Drawer(
      backgroundColor: colors.cardBg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- ШАПКА ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
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
                  Icon(Icons.settings_outlined, color: colors.textSecondary),
                ],
              ),
            ),
            Divider(color: colors.iconBg, height: 1),

            // КНОПКА ПРОФІЛЮ
            ListTile(
              leading: Icon(Icons.person_outline, color: colors.textMain),
              title: Text(
                'profile'.tr(),
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
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              },
            ),

            // КНОПКА БЕКАПУ
            ListTile(
              leading: Icon(Icons.save_alt_rounded, color: colors.textMain),
              title: Text(
                'backup_title'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                final safeContext = context;
                final sheetColors = Theme.of(
                  context,
                ).extension<AppColorsExtension>()!;

                showModalBottomSheet(
                  context: context,
                  backgroundColor: sheetColors.cardBg,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: sheetColors.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: Icon(
                              Icons.upload_file,
                              color: sheetColors.textMain,
                            ),
                            title: Text(
                              'export'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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
                            leading: Icon(
                              Icons.download,
                              color: sheetColors.expense,
                            ),
                            title: Text(
                              'import'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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

            // КНОПКА ПІДПИСОК (З ІНДИКАТОРОМ)
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
              // ДОДАНО: Червона крапочка, якщо є борги
              trailing: hasPendingSubscriptions
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.expense,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.expense.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                  : null,
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
