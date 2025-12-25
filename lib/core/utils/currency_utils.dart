/// Utility functions for currency formatting
class CurrencyUtils {
  /// Get currency symbol from currency code
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'UAH':
        return '₴';
      case 'GBP':
        return '£';
      case 'RUB':
        return '₽';
      case 'PLN':
        return 'zł';
      case 'JPY':
      case 'CNY':
        return '¥';
      default:
        return currencyCode;
    }
  }

  /// Format price with currency symbol
  static String formatPrice(double price, String currencyCode) {
    return '${getCurrencySymbol(currencyCode)} ${price.toStringAsFixed(2)}';
  }
}
