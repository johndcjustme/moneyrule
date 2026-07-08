import 'package:intl/intl.dart';

class Helper {
  static String currencyFormatter(double num, [String symbol = '₱']) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: symbol,
      decimalDigits: 2,
    );
    return currencyFormatter.format(num);
  }
}