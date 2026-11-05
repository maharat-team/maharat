String relativeDate(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 60) return 'Just now';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 14) return '1 week ago';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
  if (diff.inDays < 60) return '1 month ago';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30} months ago';
  return '${diff.inDays ~/ 365}y ago';
}
