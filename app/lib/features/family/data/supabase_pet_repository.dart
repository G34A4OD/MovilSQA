import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/read_all.dart';
import '../domain/pet_repository.dart';

class SupabasePetRepository implements PetRepository {
  const SupabasePetRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<PetRecord>> list(String familyId) async {
    final rows = await readAll(
      (from, to) => client
          .from('pets')
          .select('id,name,species,birth_date,notes,version')
          .eq('family_id', familyId)
          .order('name')
          .order('id')
          .range(from, to),
    );
    return rows
        .map(
          (r) => PetRecord(
            id: r['id'] as String,
            version: r['version'] as int,
            details: PetInput(
              name: r['name'] as String,
              species: r['species'] as String,
              birthDate: r['birth_date'] as String?,
              notes: r['notes'] as String,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(
    String familyId,
    PetInput input,
    String requestId, {
    PetRecord? existing,
  }) async {
    await client.rpc(
      'save_pet',
      params: {
        'p_family_id': familyId,
        'p_pet_id': existing?.id,
        ...input.fields,
        'p_expected_version': existing?.version,
        'p_request_id': requestId,
      },
    );
  }

  @override
  Future<void> delete(PetRecord pet) async {
    await client.rpc(
      'delete_pet',
      params: {'p_pet_id': pet.id, 'p_expected_version': pet.version},
    );
  }
}
