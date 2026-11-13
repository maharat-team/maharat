import '../l10n/l10n.dart';

String relativeDate(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 60) return tr('Just now', 'ابھی ابھی');
  if (diff.inHours < 24) {
    return tr('${diff.inHours}h ago', '${diff.inHours} گھنٹے پہلے');
  }
  if (diff.inDays == 1) return tr('Yesterday', 'کل');
  if (diff.inDays < 7) {
    return tr('${diff.inDays} days ago', '${diff.inDays} دن پہلے');
  }
  if (diff.inDays < 14) return tr('1 week ago', 'ایک ہفتہ پہلے');
  if (diff.inDays < 30) {
    final weeks = diff.inDays ~/ 7;
    return tr('$weeks weeks ago', '$weeks ہفتے پہلے');
  }
  if (diff.inDays < 60) return tr('1 month ago', 'ایک مہینہ پہلے');
  if (diff.inDays < 365) {
    final months = diff.inDays ~/ 30;
    return tr('$months months ago', '$months مہینے پہلے');
  }
  final years = diff.inDays ~/ 365;
  return tr('${years}y ago', '$years سال پہلے');
}
