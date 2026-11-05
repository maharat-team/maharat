import '../core/config/supabase_config.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  Future<UserProfileModel> fetch(String userId) async {
    final row = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfileModel.fromJson(row);
  }

  Future<void> update(String userId, Map<String, dynamic> fields) async {
    await SupabaseConfig.client
        .from('profiles')
        .update(fields)
        .eq('id', userId);
  }
}
