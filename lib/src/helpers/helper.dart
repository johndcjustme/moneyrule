import 'package:intl/intl.dart';

class Helper {
  static String currencyFormatter(double num) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );
    return currencyFormatter.format(num);
  }
}