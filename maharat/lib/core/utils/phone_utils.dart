/// Pakistani mobile numbers, stored as +92XXXXXXXXXX.
class PhoneUtils {
  static const invalidMessage =
      'Enter a valid mobile number, e.g. 0300 1234567';

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
}
