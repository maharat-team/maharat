import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class AuthService {
  GoTrueClient get _auth => SupabaseConfig.client.auth;

  String? get currentUserId => _auth.currentUser?.id;

  /// Fires on sign-out and when a session can no longer be refreshed.
  Stream<void> get onSignedOut => _auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.signedOut)
      .map((_) {});

  /// Sends a 6-digit code, creating the account on first use.
  Future<void> sendEmailOtp(String email) =>
      _auth.signInWithOtp(email: email, shouldCreateUser: true);

  Future<void> verifyEmailOtp(String email, String code) =>
      _auth.verifyOTP(type: OtpType.email, email: email, token: code);

  Future<void> signOut() => _auth.signOut();
}
