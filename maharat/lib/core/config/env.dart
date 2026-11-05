/// Client configuration injected at build time:
/// `flutter run --dart-define-from-file=env.json`
///
/// Only the project URL and publishable key belong here. The secret key must
/// never reach this app: it would be readable by anyone holding the binary.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void assertConfigured() {
    final problem = findProblem(supabaseUrl, supabasePublishableKey);
    if (problem != null) throw StateError(problem);
  }

  /// Returns why this configuration cannot work, or null if it looks valid.
  static String? findProblem(String url, String key) {
    if (url.isEmpty || key.isEmpty) {
      return 'Supabase is not configured. Copy env.example.json to env.json, '
          'fill in your values, and run with '
          '--dart-define-from-file=env.json';
    }
    if (url.contains('your-project-ref') || key.contains('your_key_here')) {
      return 'env.json still has placeholder values. Replace them with your '
          'project URL and publishable key.';
    }
    if (key.startsWith('sb_secret_')) {
      return 'A secret key must never be used in the app.';
    }
    return null;
  }
}
