import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../screens/stats_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../services/backup_service.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF5F5F7),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Text(
                    "Налаштування",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 10),

            // КНОПКА СТАТИСТИКИ
            ListTile(
              leading: const Icon(
                Icons.pie_chart_outline,
                color: Colors.black87,
              ),
              title: const Text(
                "Статистика",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Графіки та історія",
                style: TextStyle(fontSize: 12),
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

            ListTile(
              leading: const Icon(Icons.backup_outlined, color: Colors.black87),
              title: const Text(
                "Резервна копія",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Експорт та імпорт даних",
                style: TextStyle(fontSize: 12),
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
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Резервне копіювання",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.upload_file, color: Colors.green),
                          ),
                          title: const Text(
                            "Експортувати (Зберегти)",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text("Створити файл з вашими даними"),
                          onTap: () {
                            Navigator.pop(ctx);
                            // Використовуємо живі provider та safeContext
                            BackupService.exportData(provider, safeContext);
                          },
                        ),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFEBEE),
                            child: Icon(
                              Icons.settings_backup_restore,
                              color: Colors.red,
                            ),
                          ),
                          title: const Text(
                            "Імпортувати (Відновити)",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            "Увага: поточні дані будуть замінені!",
                            style: TextStyle(color: Colors.red),
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
                  ),
                );
              },
            ),

            // ДОДАЄМО КНОПКУ ПІДПИСОК
            ListTile(
              leading: const Icon(Icons.autorenew, color: Colors.black87),
              title: const Text(
                'Регулярні платежі',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
