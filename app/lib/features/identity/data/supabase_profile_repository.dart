import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile.dart';

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this.client);
  final SupabaseClient client;
  @override
  Future<PersonalProfile?> load() async {
    final actor = client.auth.currentUser?.id;
    if (actor == null) throw StateError('forbidden');
    final row = await client
        .from('profiles')
        .select(
          'user_id,public_id,full_name,version,private_profiles(blood_type,identity_card,birth_date,address)',
        )
        .eq('user_id', actor)
        .maybeSingle();
    if (row == null) return null;
    return PersonalProfile.fromJson({
      ...row,
      ...Map<String, dynamic>.from(row['private_profiles'] as Map),
    });
  }

  @override
  Future<PersonalProfile> save(
    ProfileInput input, {
    int? expectedVersion,
  }) async {
    if (!input.isValid) throw const FormatException('validation_error');
    final row = await client.rpc(
      expectedVersion == null ? 'complete_profile' : 'update_profile',
      params: {...input.toParams(), 'p_expected_version': ?expectedVersion},
    );
    return PersonalProfile.fromJson(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<void> share(
    String familyId,
    List<String> fields,
    String requestId,
  ) async {
    await client.rpc(
      'set_profile_share',
      params: {
        'p_family_id': familyId,
        'p_selected_fields': fields,
        'p_request_id': requestId,
      },
    );
  }
}
