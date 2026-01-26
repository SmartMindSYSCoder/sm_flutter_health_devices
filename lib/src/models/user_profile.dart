import 'enums.dart';

/// User profile data for health measurements (e.g. body composition)
class SmUserProfile {
  /// Height in centimeters
  final double heightCm;

  /// Weight in kilograms
  final double weightKg;

  /// User gender
  final Gender gender;

  /// Birth date in 'yyyyMMdd' format
  final String birthDate;

  const SmUserProfile({
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.birthDate,
  });

  /// Create a copy with modified fields
  SmUserProfile copyWith({
    double? heightCm,
    double? weightKg,
    Gender? gender,
    String? birthDate,
  }) {
    return SmUserProfile(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  @override
  String toString() {
    return 'SmUserProfile(height: $heightCm, weight: $weightKg, gender: $gender, birth: $birthDate)';
  }
}
