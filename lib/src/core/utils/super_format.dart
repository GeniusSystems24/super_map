// ============================================================
// core/utils/super_format.dart
// ------------------------------------------------------------
// Intl-free number / currency / byte / serial formatters shared across the kit.
// GeniusLink keeps Western digits regardless of language and renders currency
// with a leading symbol + 2-decimal precision; numerics use grouped thousands.
// ============================================================

/// Number + currency + byte formatting helpers. No `intl` dependency.
abstract final class SuperFormat {
  /// Parses a grouped/typed numeric string (`"1,234.50"`, `"-5 000"`) to a
  /// double, or null when it isn't a number.
  static double? parseNumber(String raw) {
    if (raw.trim().isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[,\s]'), '');
    return double.tryParse(cleaned);
  }

  /// Formats [n] with grouped thousands and [decimals] fraction digits:
  /// `formatNumber(1234.5) -> "1,234.50"`.
  static String formatNumber(num n, {int decimals = 2}) {
    final neg = n < 0;
    final fixed = n.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    final grouped = buf.toString();
    final frac = parts.length > 1 ? '.${parts[1]}' : '';
    return '${neg ? '-' : ''}$grouped$frac';
  }

  /// Currency with a leading [symbol] and 2-decimal precision: `$5,240.00`.
  static String currency(num n, {String symbol = r'$', int decimals = 2}) {
    final body = formatNumber(n.abs(), decimals: decimals);
    return '${n < 0 ? '-' : ''}$symbol$body';
  }

  /// A signed delta with a leading + or -: `+5,000.00` / `-5,000.00`.
  static String signed(num n, {int decimals = 2}) {
    final body = formatNumber(n.abs(), decimals: decimals);
    return '${n < 0 ? '-' : '+'}$body';
  }

  /// Human file size: `840 B`, `12 KB`, `3.4 MB`.
  static String bytes(num? b) {
    if (b == null || b.isNaN) return '';
    if (b < 1024) return '${b.toInt()} B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Truncates a long hash to `a7f8…b161` (head/tail with a horizontal ellipsis).
  static String truncateHash(String hash, {int head = 4, int tail = 4}) {
    if (hash.length <= head + tail + 1) return hash;
    return '${hash.substring(0, head)}\u2026${hash.substring(hash.length - tail)}';
  }
}
