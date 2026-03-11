class AppCurrency {
  final String code; // Наприклад: "USD"
  final String symbol; // Наприклад: "$"

  const AppCurrency({required this.code, required this.symbol});

  // Перевизначаємо оператори порівняння, щоб легко шукати валюту в списках
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCurrency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  // Конвертація в JSON для збереження в Hive
  Map<String, dynamic> toJson() {
    return {'code': code, 'symbol': symbol};
  }

  // Створення з JSON при завантаженні з Hive
  factory AppCurrency.fromJson(Map<String, dynamic> json) {
    return AppCurrency(
      code: json['code'] as String,
      symbol: json['symbol'] as String,
    );
  }

  // Заздалегідь підготовлений оптимальний список валют для широкої аудиторії
  static const List<AppCurrency> supportedCurrencies = [
    // --- Локальна базова ---
    AppCurrency(code: 'UAH', symbol: '₴'), // Українська гривня
    // --- Головні світові ---
    AppCurrency(code: 'USD', symbol: '\$'), // Долар США
    AppCurrency(code: 'EUR', symbol: '€'), // Євро
    AppCurrency(code: 'GBP', symbol: '£'), // Британський фунт
    AppCurrency(code: 'CHF', symbol: '₣'), // Швейцарський франк
    AppCurrency(code: 'JPY', symbol: '¥'), // Японська єна
    // --- Європа (не Єврозона) ---
    AppCurrency(code: 'PLN', symbol: 'zł'), // Польський злотий
    AppCurrency(code: 'CZK', symbol: 'Kč'), // Чеська крона
    AppCurrency(code: 'RON', symbol: 'lei'), // Румунський лей
    AppCurrency(code: 'HUF', symbol: 'Ft'), // Угорський форинт
    AppCurrency(code: 'BGN', symbol: 'лв'), // Болгарський лев
    AppCurrency(code: 'MDL', symbol: 'L'), // Молдовський лей
    AppCurrency(code: 'SEK', symbol: 'kr'), // Шведська крона
    AppCurrency(code: 'NOK', symbol: 'kr'), // Норвезька крона
    AppCurrency(code: 'DKK', symbol: 'kr'), // Данська крона
    // --- Кавказ, Азія, Близький Схід ---
    AppCurrency(code: 'TRY', symbol: '₺'), // Турецька ліра
    AppCurrency(code: 'GEL', symbol: '₾'), // Грузинський ларі
    AppCurrency(code: 'KZT', symbol: '₸'), // Казахстанський тенге
    AppCurrency(code: 'ILS', symbol: '₪'), // Ізраїльський шекель
    AppCurrency(code: 'AED', symbol: 'د.إ'), // Дирхам ОАЕ
    AppCurrency(code: 'CNY', symbol: '¥'), // Китайський юань
    AppCurrency(code: 'INR', symbol: '₹'), // Індійська рупія
    // --- Америка, Австралія та Океанія ---
    AppCurrency(code: 'CAD', symbol: 'C\$'), // Канадський долар
    AppCurrency(code: 'AUD', symbol: 'A\$'), // Австралійський долар
    AppCurrency(code: 'NZD', symbol: 'NZ\$'), // Новозеландський долар
    AppCurrency(code: 'BRL', symbol: 'R\$'), // Бразильський реал
    AppCurrency(code: 'MXN', symbol: 'Mex\$'), // Мексиканське песо
  ];

  // Метод для пошуку валюти за кодом (якщо не знайдено - повертає гривню)
  static AppCurrency fromCode(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first, // За замовчуванням UAH
    );
  }
}
