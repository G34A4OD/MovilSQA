class ProfileInput {
  const ProfileInput({
    required this.fullName,
    this.bloodType,
    required this.identityCard,
    required this.birthDate,
    required this.address,
  });
  final String fullName;
  final String? bloodType;
  final String identityCard;
  final String birthDate;
  final String address;
  Map<String, dynamic> toParams() => {
    'p_full_name': fullName.trim(),
    'p_blood_type': bloodType,
    'p_identity_card': identityCard.trim(),
    'p_birth_date': birthDate,
    'p_address': address.trim(),
  };
  bool get isValid {
    final date = DateTime.tryParse(birthDate);
    final today = DateTime.now();
    return fullName.trim().length >= 2 &&
        fullName.trim().length <= 120 &&
        identityCard.trim().length >= 3 &&
        identityCard.trim().length <= 30 &&
        address.trim().length >= 3 &&
        address.trim().length <= 250 &&
        date != null &&
        date.toIso8601String().split('T').first == birthDate &&
        date.year >= 1900 &&
        !date.isAfter(today) &&
        (bloodType == null || bloodTypes.contains(bloodType));
  }

  static const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
}

class PersonalProfile {
  const PersonalProfile({
    required this.userId,
    required this.publicId,
    required this.version,
    required this.details,
  });
  final String userId;
  final String publicId;
  final int version;
  final ProfileInput details;
  factory PersonalProfile.fromJson(Map<String, dynamic> row) => PersonalProfile(
    userId: row['user_id'] as String,
    publicId: row['public_id'] as String,
    version: row['version'] as int,
    details: ProfileInput(
      fullName: row['full_name'] as String,
      bloodType: row['blood_type'] as String?,
      identityCard: row['identity_card'] as String,
      birthDate: row['birth_date'] as String,
      address: row['address'] as String,
    ),
  );
}

abstract interface class ProfileRepository {
  Future<PersonalProfile?> load();
  Future<PersonalProfile> save(ProfileInput input, {int? expectedVersion});
  Future<void> share(String familyId, List<String> fields, String requestId);
}
