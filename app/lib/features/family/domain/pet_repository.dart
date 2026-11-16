class PetInput {
  const PetInput({
    required this.name,
    required this.species,
    this.birthDate,
    this.notes = '',
  });
  final String name, species, notes;
  final String? birthDate;
  bool get isValid {
    final parsed = birthDate == null ? null : DateTime.tryParse(birthDate!);
    return name.trim().isNotEmpty &&
        name.trim().length <= 100 &&
        species.trim().isNotEmpty &&
        species.trim().length <= 60 &&
        notes.length <= 1000 &&
        (birthDate == null ||
            parsed != null &&
                parsed.year >= 1900 &&
                !parsed.isAfter(DateTime.now()) &&
                parsed.toIso8601String().split('T').first == birthDate);
  }

  Map<String, dynamic> get fields => {
    'p_name': name.trim(),
    'p_species': species.trim(),
    'p_birth_date': birthDate,
    'p_notes': notes,
  };
}

class PetRecord {
  const PetRecord({
    required this.id,
    required this.version,
    required this.details,
  });
  final String id;
  final int version;
  final PetInput details;
}

abstract interface class PetRepository {
  Future<List<PetRecord>> list(String familyId);
  Future<void> save(
    String familyId,
    PetInput input,
    String requestId, {
    PetRecord? existing,
  });
  Future<void> delete(PetRecord pet);
}
