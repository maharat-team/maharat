import '../l10n/l10n.dart';

/// Pakistani mobile numbers, stored as +92XXXXXXXXXX.
class PhoneUtils {
  static String get invalidMessage => tr(
    'Enter a valid mobile number, e.g. 0300 1234567',
    'درست موبائل نمبر درج کریں، مثلاً 0300 1234567',
  );

  /// Accepts 03001234567, 3001234567, 923001234567 and +92 300 1234567.
  /// Returns null when the input is not a valid mobile number.
  static String? normalize(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length != 10 || !digits.startsWith('3')) return null;
    return '+92$digits';
  }

  static String? validate(String? input) =>
      normalize(input ?? '') == null ? invalidMessage : null;

  /// +923001234567 -> 0300 1234567, the way people in Pakistan write it.
  static String display(String stored) {
    if (!stored.startsWith('+92') || stored.length != 13) return stored;
    return '0${stored.substring(3, 6)} ${stored.substring(6)}';
  }
}
