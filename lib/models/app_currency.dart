class AppCurrency {
  final String code; // Наприклад: "USD"
  final String symbol; // Наприклад: "$"

  const AppCurrency({required this.code, required this.symbol});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCurrency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  Map<String, dynamic> toJson() {
    return {'code': code, 'symbol': symbol};
  }

  factory AppCurrency.fromJson(Map<String, dynamic> json) {
    return AppCurrency(
      code: json['code'] as String,
      symbol: json['symbol'] as String,
    );
  }

  static const List<AppCurrency> supportedCurrencies = [
    AppCurrency(code: 'UAH', symbol: '₴'),
    AppCurrency(code: 'USD', symbol: '\$'),
    AppCurrency(code: 'EUR', symbol: '€'),
    AppCurrency(code: 'GBP', symbol: '£'),
    AppCurrency(code: 'CHF', symbol: '₣'),
    AppCurrency(code: 'JPY', symbol: '¥'),
    AppCurrency(code: 'PLN', symbol: 'zł'),
    AppCurrency(code: 'CZK', symbol: 'Kč'),
    AppCurrency(code: 'RON', symbol: 'lei'),
    AppCurrency(code: 'HUF', symbol: 'Ft'),
    AppCurrency(code: 'BGN', symbol: 'лв'),
    AppCurrency(code: 'MDL', symbol: 'L'),
    AppCurrency(code: 'SEK', symbol: 'kr'),
    AppCurrency(code: 'NOK', symbol: 'kr'),
    AppCurrency(code: 'DKK', symbol: 'kr'),
    AppCurrency(code: 'TRY', symbol: '₺'),
    AppCurrency(code: 'GEL', symbol: '₾'),
    AppCurrency(code: 'KZT', symbol: '₸'),
    AppCurrency(code: 'ILS', symbol: '₪'),
    AppCurrency(code: 'AED', symbol: 'د.إ'),
    AppCurrency(code: 'CNY', symbol: '¥'),
    AppCurrency(code: 'INR', symbol: '₹'),
    AppCurrency(code: 'CAD', symbol: 'C\$'),
    AppCurrency(code: 'AUD', symbol: 'A\$'),
    AppCurrency(code: 'NZD', symbol: 'NZ\$'),
    AppCurrency(code: 'BRL', symbol: 'R\$'),
    AppCurrency(code: 'MXN', symbol: 'Mex\$'),
  ];

  // 👇 ОПТИМІЗАЦІЯ: Кеш для миттєвого доступу (O(1) замість O(N))
  static final Map<String, AppCurrency> _currencyCache = {
    for (var c in supportedCurrencies) c.code: c,
  };

  static AppCurrency fromCode(String code) {
    // Миттєво дістаємо з Map, а не перебираємо список
    return _currencyCache[code.toUpperCase()] ?? supportedCurrencies.first;
  }
}
