import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns backend failures into text that is safe and useful to show a user.
String friendlyError(Object error) {
  const fallback = 'Something went wrong. Please try again.';
  const offline = 'No internet connection. Please check it and try again.';

  if (error is AuthException) {
    final code = error.code ?? '';
    if (error.statusCode == '429' || code.contains('rate_limit')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (code == 'otp_expired' || code == 'invalid_credentials') {
      return 'That code is wrong or has expired. Please try again.';
    }
    if (code == 'validation_failed' || code == 'email_address_invalid') {
      return 'Please enter a valid email address.';
    }
    if (error is AuthRetryableFetchException) return offline;
    return fallback;
  }
  if (error is PostgrestException) {
    // P0001 is raised by our own triggers with user-facing wording.
    return error.code == 'P0001' ? error.message : fallback;
  }
  if (error is StorageException) {
    return 'The photo could not be uploaded. Please try again.';
  }
  if (error is TimeoutException) return offline;
  if (error is FormatException) return error.message;

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup')) {
    return offline;
  }
  return fallback;
}
