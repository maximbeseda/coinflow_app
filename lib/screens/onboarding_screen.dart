import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../providers/all_providers.dart';
import '../services/storage_service.dart';
import '../models/app_currency.dart';
import '../theme/app_colors_extension.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late TextEditingController _currencyCtrl;
  late TextEditingController _languageCtrl;

  String _selectedCurrencyCode = 'USD';
  bool _isSaving = false;
  bool _isInitialized = false;

  final List<Map<String, String>> _supportedLanguages = [
    {'code': 'uk', 'name': 'Українська', 'short': 'UK'},
    {'code': 'en', 'name': 'English', 'short': 'EN'},
    {'code': 'de', 'name': 'Deutsch', 'short': 'DE'},
  ];

  @override
  void initState() {
    super.initState();
    _currencyCtrl = TextEditingController();
    _languageCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _autoDetectDefaults();
      _isInitialized = true;
    }
  }

  void _autoDetectDefaults() {
    final deviceLocale = ui.PlatformDispatcher.instance.locale;
    final deviceLangCode = deviceLocale.languageCode;
    final deviceCountryCode = deviceLocale.countryCode ?? '';

    final initialLang = _supportedLanguages.firstWhere(
      (lang) => lang['code'] == deviceLangCode,
      orElse: () =>
          _supportedLanguages.firstWhere((lang) => lang['code'] == 'en'),
    );

    String initialCurrency = 'USD';

    final Map<String, String> countryToCurrency = {
      'UA': 'UAH',
      'US': 'USD',
      'GB': 'GBP',
      'PL': 'PLN',
      'CA': 'CAD',
      'AU': 'AUD',
      'JP': 'JPY',
      'CH': 'CHF',
      'DE': 'EUR',
      'FR': 'EUR',
      'IT': 'EUR',
      'ES': 'EUR',
      'NL': 'EUR',
      'AT': 'EUR',
      'BE': 'EUR',
      'FI': 'EUR',
      'IE': 'EUR',
      'PT': 'EUR',
      'GR': 'EUR',
    };

    if (countryToCurrency.containsKey(deviceCountryCode)) {
      initialCurrency = countryToCurrency[deviceCountryCode]!;
    } else {
      if (initialLang['code'] == 'uk') initialCurrency = 'UAH';
      if (initialLang['code'] == 'de') initialCurrency = 'EUR';
    }

    bool isCurrencySupported = AppCurrency.supportedCurrencies.any(
      (c) => c.code == initialCurrency,
    );
    if (!isCurrencySupported) {
      initialCurrency = 'USD';
    }

    _selectedCurrencyCode = initialCurrency;
    _currencyCtrl.text = initialCurrency;
    _languageCtrl.text = initialLang['name']!;

    if (context.locale.languageCode != initialLang['code']) {
      final code = initialLang['code']!;
      Future.microtask(() {
        if (mounted) {
          context.setLocale(Locale(code));
        }
      });
    }
  }

  @override
  void dispose() {
    _currencyCtrl.dispose();
    _languageCtrl.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    setState(() => _isSaving = true);

    final settingsNotifier = ref.read(settingsProvider.notifier);

    await settingsNotifier.setBaseCurrency(_selectedCurrencyCode);
    await StorageService.completeOnboarding();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _openLanguagePicker(AppColorsExtension colors) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'language_title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = _supportedLanguages[index];
                    bool isSelected =
                        context.locale.languageCode == lang['code'];

                    return ListTile(
                      onTap: () async {
                        await context.setLocale(Locale(lang['code']!));

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);

                        if (!mounted) return;
                        setState(() {
                          _languageCtrl.text = lang['name']!;
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected
                            ? colors.textMain
                            : colors.iconBg,
                        child: Text(
                          lang['short']!,
                          style: TextStyle(
                            color: isSelected ? colors.cardBg : colors.textMain,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          color: colors.textMain,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colors.textMain)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCurrencyPicker(AppColorsExtension colors) {
    FocusScope.of(context).unfocus();
    List<String> availableCurrencies = AppCurrency.supportedCurrencies
        .map((c) => c.code)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'base_currency_title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableCurrencies.length,
                  itemBuilder: (context, index) {
                    final code = availableCurrencies[index];
                    final curr = AppCurrency.fromCode(code);
                    bool isSelected = _selectedCurrencyCode == code;

                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedCurrencyCode = code;
                          _currencyCtrl.text = code;
                        });
                        Navigator.pop(ctx);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected
                            ? colors.textMain
                            : colors.iconBg,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              curr.symbol.trim(),
                              style: TextStyle(
                                color: isSelected
                                    ? colors.cardBg
                                    : colors.textMain,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        curr.code,
                        style: TextStyle(
                          color: colors.textMain,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colors.textMain)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorField({
    required TextEditingController controller,
    required String label,
    required AppColorsExtension colors,
    required VoidCallback onTap,
    Widget? prefix,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: InputDecorator(
        isEmpty: controller.text.isEmpty && prefix == null,
        decoration: InputDecoration(
          filled: false,
          labelText: label,
          labelStyle: TextStyle(color: colors.textSecondary, fontSize: 16),
          floatingLabelStyle: TextStyle(
            color: colors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          prefix: prefix,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: colors.textSecondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.textMain, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            const Text(
              'Wj',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.transparent,
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.text,
                    style: TextStyle(
                      color: colors.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
    final currentLocaleCode = context.locale.languageCode;

    final currentLang = _supportedLanguages.firstWhere(
      (lang) => lang['code'] == currentLocaleCode,
      orElse: () => _supportedLanguages.first,
    );

    final currencySymbol = AppCurrency.fromCode(_selectedCurrencyCode).symbol;

    return Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Логотип
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 32),

                // Привітання
                Text(
                  'onboarding_title'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'onboarding_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSelectorField(
                        controller: _languageCtrl,
                        label: 'language_title'.tr(),
                        colors: colors,
                        onTap: () => _openLanguagePicker(colors),
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: colors.iconBg,
                            child: Text(
                              currentLang['short']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.textMain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSelectorField(
                        controller: _currencyCtrl,
                        label: 'base_currency_title'.tr(),
                        colors: colors,
                        onTap: () => _openCurrencyPicker(colors),
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: colors.iconBg,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Text(
                                  currencySymbol.trim(),
                                  style: TextStyle(
                                    color: colors.textMain,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // КНОПКА СТАРТУ (змінили назву тут)
                _buildStartButton(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 👇 Змінили назву функції на правильну (lowerCamelCase)
  Widget _buildStartButton(AppColorsExtension colors) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _finishOnboarding,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.textMain,
        foregroundColor: colors.cardBg,
        minimumSize: const Size(double.infinity, 56),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
      child: _isSaving
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: colors.cardBg,
                strokeWidth: 2,
              ),
            )
          : Text(
              'get_started'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
