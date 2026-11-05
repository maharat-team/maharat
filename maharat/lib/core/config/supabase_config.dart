import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// The single entry point to the Supabase client.
class SupabaseConfig {
  static Future<void> initialize() async {
    Env.assertConfigured();
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
