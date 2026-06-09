import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final currencyServiceProvider =
    StateNotifierProvider<CurrencyService, CurrencyState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return CurrencyService(prefs);
    });

class CurrencyState {
  const CurrencyState({
    required this.selectedCurrency,
    required this.rates,
    this.lastUpdated,
    this.isRefreshing = false,
  });

  final String selectedCurrency;
  final Map<String, double> rates;
  final DateTime? lastUpdated;
  final bool isRefreshing;

  CurrencyState copyWith({
    String? selectedCurrency,
    Map<String, double>? rates,
    DateTime? lastUpdated,
    bool? isRefreshing,
  }) {
    return CurrencyState(
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      rates: rates ?? this.rates,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class CurrencyService extends StateNotifier<CurrencyState> {
  final SharedPreferences _prefs;
  static const String _currencyKey = 'base_currency';
  static const String _ratesKey = 'exchange_rates_usd';
  static const String _ratesUpdatedKey = 'exchange_rates_updated_at';
  static const String _ratesEndpoint =
      'https://api.frankfurter.dev/v1/latest?base=USD';
  static const Duration _ratesMaxAge = Duration(hours: 12);

  CurrencyService(this._prefs)
    : super(
        CurrencyState(
          selectedCurrency: _prefs.getString(_currencyKey) ?? 'USD',
          rates: _loadCachedRates(_prefs),
          lastUpdated: _loadCachedUpdatedAt(_prefs),
        ),
      ) {
    if (_ratesAreStale(state.lastUpdated)) {
      unawaited(refreshRates());
    }
  }

  Future<void> setBaseCurrency(String currency) async {
    state = state.copyWith(selectedCurrency: currency);
    await _prefs.setString(_currencyKey, currency);
    if (_ratesAreStale(state.lastUpdated)) {
      unawaited(refreshRates());
    }
  }

  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'INR',
    'JPY',
    'GBP',
    'CNY',
    'AUD',
    'CAD',
    'CHF',
    'NZD',
    'SGD',
    'HKD',
    'AED',
    'BRL',
    'MXN',
    'ZAR',
  ];

  static const Map<String, double> fallbackRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'INR': 83.2,
    'JPY': 150.5,
    'GBP': 0.79,
    'CNY': 7.23,
    'AUD': 1.52,
    'CAD': 1.36,
    'CHF': 0.88,
    'NZD': 1.66,
    'SGD': 1.34,
    'HKD': 7.82,
    'AED': 3.67,
    'BRL': 5.15,
    'MXN': 17.0,
    'ZAR': 18.2,
  };

  double convert(double amount, String fromCurrency, {String? toCurrency}) {
    final targetCurrency = toCurrency ?? state.selectedCurrency;

    if (fromCurrency == targetCurrency) return amount;

    final fromRate =
        state.rates[fromCurrency] ?? fallbackRates[fromCurrency] ?? 1.0;
    final toRate =
        state.rates[targetCurrency] ?? fallbackRates[targetCurrency] ?? 1.0;

    final amountInUSD = amount / fromRate;
    return amountInUSD * toRate;
  }

  Future<void> refreshRates() async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true);

    try {
      final response = await http
          .get(Uri.parse(_ratesEndpoint))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Exchange rate refresh failed.');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawRates = decoded['rates'] as Map<String, dynamic>? ?? {};
      final nextRates = <String, double>{'USD': 1.0};

      for (final entry in rawRates.entries) {
        final value = entry.value;
        if (value is num) {
          nextRates[entry.key.toUpperCase()] = value.toDouble();
        }
      }

      final updatedAt = DateTime.now();
      await _prefs.setString(_ratesKey, jsonEncode(nextRates));
      await _prefs.setString(_ratesUpdatedKey, updatedAt.toIso8601String());

      state = state.copyWith(
        rates: nextRates,
        lastUpdated: updatedAt,
        isRefreshing: false,
      );
    } catch (_) {
      state = state.copyWith(isRefreshing: false);
    }
  }

  static Map<String, double> _loadCachedRates(SharedPreferences prefs) {
    final cached = prefs.getString(_ratesKey);
    if (cached == null) return fallbackRates;

    try {
      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is num)
            entry.key.toUpperCase(): (entry.value as num).toDouble(),
      };
    } catch (_) {
      return fallbackRates;
    }
  }

  static DateTime? _loadCachedUpdatedAt(SharedPreferences prefs) {
    final cached = prefs.getString(_ratesUpdatedKey);
    if (cached == null) return null;
    return DateTime.tryParse(cached);
  }

  static bool _ratesAreStale(DateTime? lastUpdated) {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated) > _ratesMaxAge;
  }
}
