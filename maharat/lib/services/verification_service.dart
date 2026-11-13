import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/verification_info.dart';
import '../models/worker_model.dart';

/// Runs the automatic CNIC-to-selfie face check (Edge Function
/// `verify-identity`). The function writes the result to the database itself;
/// this returns it so the app can show it straight away.
class VerificationService {
  Future<FaceCheckResult> check({required bool contractor}) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'verify-identity',
        body: {'kind': contractor ? 'contractor' : 'worker'},
      );
      return _parse(response.data);
    } on FunctionException catch (error) {
      // The application is saved; it stays pending and can be checked again.
      debugPrint('Face check failed: ${error.status} ${error.details}');
      return _parse(error.details) ??
          const FaceCheckResult(
            status: VerificationStatus.pending,
            code: 'temporary_error',
          );
    }
  }

  static FaceCheckResult _parse(Object? data) {
    if (data is! Map) {
      return const FaceCheckResult(
        status: VerificationStatus.pending,
        code: 'temporary_error',
      );
    }
    final status = VerificationStatus.values.asNameMap()[data['status']];
    return FaceCheckResult(
      status: status ?? VerificationStatus.pending,
      score: (data['score'] as num?)?.toDouble(),
      code: data['code'] as String?,
    );
  }
}
