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
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'Supabase is not configured. Copy env.example.json to env.json and '
        'run with --dart-define-from-file=env.json',
      );
    }
    if (supabasePublishableKey.startsWith('sb_secret_')) {
      throw StateError('A secret key must never be used in the app.');
    }
  }
}
