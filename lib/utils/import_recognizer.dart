import 'package:flutter/material.dart';
import '../database/app_database.dart';

class ImportRecognizer {
  // ==========================================
  // 1. СЛОВНИКИ ДЛЯ РОЗПІЗНАВАННЯ ІКОНОК
  // ==========================================
  static const Map<int, List<String>> _iconKeywords = {
    // 🍔 Icons.restaurant (Їжа / Food)
    0xe532: [
      'кафе',
      'ресторан',
      'їжа',
      'харчування',
      'food',
      'cafe',
      'dining',
      'meal',
      'lunch',
      'dinner',
      'restaurant',
      'essen',
      'kaffee',
      'nourriture',
      'repas',
      'comida',
      'cena',
      'pranzo',
    ],
    // 🚗 Icons.directions_car (Транспорт / Transport)
    0xe1d7: [
      'авто',
      'таксі',
      'транспорт',
      'пальне',
      'бензин',
      'car',
      'taxi',
      'uber',
      'lyft',
      'gas',
      'fuel',
      'transit',
      'transport',
      'benzin',
      'tanken',
      'auto',
      'voiture',
      'essence',
      'coche',
      'gasolina',
    ],
    // 💰 Icons.payments (Доходи / Income)
    0xe4a1: [
      'зарплата',
      'премія',
      'аванс',
      'бонус',
      'salary',
      'income',
      'wage',
      'bonus',
      'paycheck',
      'gehalt',
      'lohn',
      'einkommen',
      'salaire',
      'paie',
      'salario',
      'sueldo',
      'ingreso',
    ],
    // 🛒 Icons.shopping_basket (Продукти / Шопінг)
    0xe5c3: [
      'продукти',
      'маркет',
      'сільпо',
      'атб',
      'ашан',
      'магазин',
      'покупки',
      'groceries',
      'shop',
      'store',
      'market',
      'supermarket',
      'lebensmittel',
      'supermarkt',
      'einkaufen',
      'courses',
      'supermarché',
      'compras',
      'supermercado',
    ],
    // 💊 Icons.medical_services (Здоров'я / Health)
    0xe3ed: [
      'здоров',
      'аптека',
      'лікар',
      'медицина',
      'health',
      'doctor',
      'pharmacy',
      'medicine',
      'hospital',
      'gesundheit',
      'arzt',
      'apotheke',
      'medizin',
      'santé',
      'médecin',
      'pharmacie',
      'salud',
      'médico',
      'farmacia',
    ],
    // 💳 Icons.account_balance_wallet (Рахунки / Accounts)
    0xe041: [
      'картка',
      'банк',
      'приват',
      'моно',
      'ощад',
      'готівка',
      'гаманець',
      'wallet',
      'cash',
      'card',
      'bank',
      'account',
      'atm',
      'bargeld',
      'karte',
      'konto',
      'brieftasche',
      'espèces',
      'carte',
      'banque',
      'efectivo',
      'tarjeta',
      'banco',
    ],
    // 🏠 Icons.home (Дім / Комуналка)
    0xe314: [
      'комунал',
      'дім',
      'квартира',
      'оренда',
      'ремонт',
      'home',
      'rent',
      'house',
      'utilities',
      'bills',
      'miete',
      'haus',
      'wohnung',
      'strom',
      'maison',
      'loyer',
      'casa',
      'alquiler',
      'luz',
      'agua',
    ],
  };

  static int getIconForName(String name) {
    final n = name.toLowerCase();
    for (var entry in _iconKeywords.entries) {
      if (entry.value.any((keyword) => n.contains(keyword))) {
        return entry.key; // Повертаємо код знайденої іконки
      }
    }
    return Icons
        .category
        .codePoint; // Дефолтна іконка (якщо нічого не знайдено)
  }

  // ==========================================
  // 2. СЛОВНИКИ ДЛЯ РОЗПІЗНАВАННЯ ТИПУ КАТЕГОРІЇ
  // ==========================================
  static const List<String> _incomeKeywords = [
    'зарплата',
    'дохід',
    'премія',
    'пай',
    'подарунок',
    'відсотки',
    'salary',
    'income',
    'bonus',
    'wage',
    'paycheck',
    'gift',
    'interest',
    'dividend',
    'gehalt',
    'lohn',
    'einkommen',
    'geschenk',
    'zinsen',
    'salaire',
    'revenu',
    'prime',
    'cadeau',
    'intérêts',
    'salario',
    'sueldo',
    'ingreso',
    'regalo',
    'intereses',
  ];

  static const List<String> _accountKeywords = [
    'картка',
    'банк',
    'приват',
    'моно',
    'ощад',
    'готівка',
    'usd',
    'eur',
    'gbp',
    'chf',
    'pln',
    'пф',
    'гаманець',
    'рахунок',
    'wallet',
    'card',
    'account',
    'cash',
    'bank',
    'bargeld',
    'konto',
    'karte',
    'espèces',
    'carte',
    'banque',
    'efectivo',
    'tarjeta',
    'banco',
  ];

  static const List<String> _expenseKeywords = [
    'продукти',
    'кафе',
    'транспорт',
    'ремонт',
    'їжа',
    'комунал',
    'покупки',
    'одяг',
    'food',
    'expense',
    'rent',
    'groceries',
    'shopping',
    'clothes',
    'bills',
    'utilities',
    'spend',
    'essen',
    'einkaufen',
    'miete',
    'kleidung',
    'rechnungen',
    'ausgabe',
    'courses',
    'loyer',
    'vêtements',
    'factures',
    'dépense',
    'comida',
    'compras',
    'alquiler',
    'ropa',
    'facturas',
    'gasto',
  ];

  static CategoryType guessType(String name, {required bool isFrom}) {
    final n = name.toLowerCase();

    if (_incomeKeywords.any((k) => n.contains(k))) return CategoryType.income;
    if (_accountKeywords.any((k) => n.contains(k))) return CategoryType.account;
    if (_expenseKeywords.any((k) => n.contains(k))) return CategoryType.expense;

    // Якщо не вгадали за назвою, дивимось на контекст (звідки чи куди йшли гроші)
    return isFrom ? CategoryType.account : CategoryType.expense;
  }

  // ==========================================
  // 3. РОЗПІЗНАВАННЯ НАЗВ КОЛОНОК З РІЗНИХ БАНКІВ
  // ==========================================
  static bool isDate(String h) => [
    'данные',
    'дата',
    'date',
    'time',
    'день',
    'datum',
    'zeit',
    'temps',
    'fecha',
    'hora',
  ].contains(h);

  static bool isFrom(String h) => [
    'из',
    'from',
    'счет списания',
    'джерело',
    'від',
    'source',
    'account',
    'von',
    'quelle',
    'de',
    'desde',
    'origen',
  ].contains(h);

  static bool isTo(String h) => [
    'в',
    'to',
    'счет зачисления',
    'категория',
    'куди',
    'target',
    'category',
    'payee',
    'nach',
    'ziel',
    'kategorie',
    'à',
    'vers',
    'catégorie',
    'a',
    'hacia',
    'categoría',
  ].contains(h);

  static bool isAmountFrom(String h) => [
    'сумма',
    'amount',
    'сума',
    'выход',
    'витрачено',
    'value',
    'sum',
    'withdrawal',
    'betrag',
    'summe',
    'ausgabe',
    'montant',
    'somme',
    'dépense',
    'importe',
    'cantidad',
    'suma',
    'gasto',
  ].contains(h);

  static bool isCurrencyFrom(String h) => [
    'валюта',
    'currency',
    'валюта списания',
    'währung',
    'devise',
    'moneda',
  ].contains(h);

  static bool isNote(String h) => [
    'заметка',
    'comment',
    'коментар',
    'описание',
    'note',
    'desc',
    'description',
    'memo',
    'notiz',
    'kommentar',
    'beschreibung',
    'commentaire',
    'nota',
    'comentario',
    'descripción',
  ].contains(h);

  // Для цих колонок банки зазвичай використовують довгі фрази, тому залишаємо .contains()
  static bool isAmountTo(String h) =>
      h.contains('сумма (в валюте') ||
      h.contains('сумма в др') ||
      h.contains('приход') ||
      h.contains('отримано') ||
      h.contains('deposit') ||
      h.contains('inflow') ||
      h.contains('target amount') ||
      h.contains('einnahme') ||
      h.contains('einzahlung') ||
      h.contains('dépôt') ||
      h.contains('revenu') ||
      h.contains('depósito') ||
      h.contains('ingreso');

  static bool isCurrencyTo(String h) =>
      h.contains('валюта операции') ||
      h.contains('др.валюта') ||
      h.contains('валюта зачисления') ||
      h.contains('target currency') ||
      h.contains('zielwährung') ||
      h.contains('devise cible') ||
      h.contains('moneda de destino');
}
