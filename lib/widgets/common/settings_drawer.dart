import 'package:flutter/material.dart';
// 👇 1. Замінили provider на flutter_riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../screens/stats_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../services/backup_service.dart';
import '../../screens/profile_screen.dart';
import '../../screens/currencies_screen.dart';
// 👇 ДОДАНО: Імпорт нашого нового екрану
import '../../screens/import_export_screen.dart';
import '../../theme/app_colors_extension.dart';

// 👇 2. Імпортуємо наш єдиний хаб провайдерів
import '../../providers/all_providers.dart';

// 👇 3. Змінили StatelessWidget на ConsumerWidget
class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  @override
  // 👇 4. Додали WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // 👇 5. Отримуємо стан підписок напряму через ref
    final hasPendingSubscriptions = ref
        .watch(subscriptionProvider)
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

            // КНОПКА КУРСИ ВАЛЮТ
            ListTile(
              leading: Icon(Icons.currency_exchange, color: colors.textMain),
              title: Text(
                'exchange_rates'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textMain,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrenciesScreen(),
                  ),
                );
              },
            ),

            // 👇 ДОДАНО: КНОПКА ЕКСПОРТУ/ІМПОРТУ (CSV)
            ListTile(
              leading: Icon(Icons.import_export, color: colors.textMain),
              title: Text(
                'data_management'
                    .tr(), // Або інший ключ, який тобі більше подобається
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context); // Закриваємо бокове меню
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportExportScreen(),
                  ),
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
                final navContext = Navigator.of(context).context;
                final sheetColors = Theme.of(
                  context,
                ).extension<AppColorsExtension>()!;

                Navigator.pop(context);

                showModalBottomSheet(
                  context: navContext,
                  backgroundColor: sheetColors.cardBg,
                  isScrollControlled: true,
                  builder: (ctx) => const _BackupBottomSheet(),
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

// ==========================================
// INLINE BOTTOM SHEET ДЛЯ БЕКАПУ
// ==========================================
enum _ExpandedMode { none, export, import }

class _BackupBottomSheet extends ConsumerStatefulWidget {
  const _BackupBottomSheet();

  @override
  ConsumerState<_BackupBottomSheet> createState() => _BackupBottomSheetState();
}

class _BackupBottomSheetState extends ConsumerState<_BackupBottomSheet> {
  _ExpandedMode _expandedMode = _ExpandedMode.none;
  bool _isObscured = true;
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleExpand(_ExpandedMode mode) {
    setState(() {
      if (_expandedMode == mode) {
        _expandedMode = _ExpandedMode.none;
        _focusNode.unfocus();
      } else {
        _expandedMode = mode;
        _passwordCtrl.clear();
        _isObscured = true;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _focusNode.requestFocus();
        });
      }
    });
  }

  void _submit() {
    final pwd = _passwordCtrl.text;
    if (pwd.isEmpty) return;

    final mode = _expandedMode;
    final rootContext = Navigator.of(context).context;

    Navigator.pop(context);

    if (mode == _ExpandedMode.export) {
      BackupService.exportData(rootContext, ref, pwd);
    } else if (mode == _ExpandedMode.import) {
      BackupService.importData(rootContext, ref, pwd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Icon(Icons.upload_file, color: colors.textMain),
              title: Text(
                'export'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              subtitle: Text(
                'export_subtitle'.tr(),
                style: TextStyle(color: colors.textSecondary),
              ),
              onTap: () => _toggleExpand(_ExpandedMode.export),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expandedMode == _ExpandedMode.export
                  ? _buildInlinePasswordField(colors)
                  : const SizedBox.shrink(),
            ),

            ListTile(
              leading: Icon(Icons.download, color: colors.expense),
              title: Text(
                'import'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              subtitle: Text(
                'warning_overwrite'.tr(),
                style: TextStyle(color: colors.expense),
              ),
              onTap: () => _toggleExpand(_ExpandedMode.import),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expandedMode == _ExpandedMode.import
                  ? _buildInlinePasswordField(colors)
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInlinePasswordField(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              _expandedMode == _ExpandedMode.export
                  ? 'enter_password_export'.tr()
                  : 'enter_password_import'.tr(),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextField(
            controller: _passwordCtrl,
            focusNode: _focusNode,
            obscureText: _isObscured,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: TextStyle(color: colors.textMain, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'password'.tr(),
              hintStyle: TextStyle(
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: colors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: colors.textMain,
                      size: 28,
                    ),
                    onPressed: _submit,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
