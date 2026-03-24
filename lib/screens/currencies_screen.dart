import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/settings_provider.dart';
import '../models/app_currency.dart';
import '../utils/date_formatter.dart';
import '../theme/app_colors_extension.dart';

class CurrenciesScreen extends StatelessWidget {
  const CurrenciesScreen({super.key});

  // 👇 ДОДАНО: Спеціальний форматер курсу для списку валют
  String _formatRate(double val) {
    String formatted = val.toStringAsFixed(4);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0*$'), '');
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    return formatted;
  }

  void _showAddCurrencyDialog(BuildContext context, SettingsProvider settings) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final availableCurrencies = AppCurrency.supportedCurrencies
        .where((c) => !settings.selectedCurrencies.contains(c.code))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      builder: (ctx) => SafeArea(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'add_currency'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (availableCurrencies.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'all_currencies_added'.tr(),
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availableCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = availableCurrencies[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.iconBg,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currency.symbol,
                              style: TextStyle(
                                color: colors.textMain,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        currency.code,
                        style: TextStyle(color: colors.textMain),
                      ),
                      onTap: () {
                        settings.toggleSelectedCurrency(currency.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final settings = context.watch<SettingsProvider>();
    final baseCurrency = AppCurrency.fromCode(settings.baseCurrency);

    return Scaffold(
      backgroundColor: colors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textMain),
        title: Text(
          'exchange_rates'.tr(),
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('updating_rates'.tr()),
                  duration: const Duration(seconds: 1),
                ),
              );
              await settings.forceUpdateRates();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (settings.lastRatesUpdate != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${'last_update'.tr()}: ${DateFormatter.formatWithTime(settings.lastRatesUpdate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: settings.selectedCurrencies.length,
                itemBuilder: (context, index) {
                  final code = settings.selectedCurrencies[index];
                  final currency = AppCurrency.fromCode(code);

                  if (code == settings.baseCurrency) {
                    return _buildCurrencyCard(
                      context,
                      currency: currency,
                      isBase: true,
                      rateText: 'base_currency'.tr(),
                      colors: colors,
                    );
                  }

                  final rate = settings.exchangeRates[code];

                  // 👇 ЗМІНЕНО: Використовуємо наш новий форматер до 4 знаків
                  final rateText = rate != null
                      ? "1 ${currency.symbol} = ${_formatRate(1 / rate)} ${baseCurrency.symbol}"
                      : "loading".tr();

                  return _buildCurrencyCard(
                    context,
                    currency: currency,
                    isBase: false,
                    rateText: rateText,
                    colors: colors,
                    onDelete: () => settings.toggleSelectedCurrency(code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.income,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddCurrencyDialog(context, settings),
      ),
    );
  }

  Widget _buildCurrencyCard(
    BuildContext context, {
    required AppCurrency currency,
    required bool isBase,
    required String rateText,
    required AppColorsExtension colors,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(12), // Строгий дизайн 12
        border: isBase
            ? Border.all(color: colors.income.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isBase
              ? colors.income.withValues(alpha: 0.2)
              : colors.iconBg,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                currency.symbol,
                style: TextStyle(
                  color: isBase ? colors.income : colors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          currency.code,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textMain),
        ),
        subtitle: Text(
          rateText,
          style: TextStyle(
            color: isBase ? colors.income : colors.textSecondary,
          ),
        ),
        trailing: !isBase && onDelete != null
            ? IconButton(
                icon: Icon(Icons.delete_outline, color: colors.expense),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}
