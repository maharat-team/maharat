import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// The single entry point to the Supabase client.
class SupabaseConfig {
  static Future<void> initialize() async {
    Env.assertConfigured();
    if (!kReleaseMode) {
      debugPrint('[config] Supabase host: ${Uri.parse(Env.supabaseUrl).host}');
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
