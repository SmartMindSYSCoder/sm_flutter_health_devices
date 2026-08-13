import 'enums.dart';

/// User profile data for health measurements (e.g. body composition)
class SmUserProfile {
  /// Height in centimeters
  final double heightCm;

  /// Weight in kilograms
  final double weightKg;

  /// User gender
  final Gender gender;

  /// User birth date
  final DateTime birthDate;

  const SmUserProfile({
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.birthDate,
  });

  /// Formatted birth date as 'YYYYMMDD' for native SDKs
  String get formattedBirthDate {
    return '${birthDate.year}'
        '${birthDate.month.toString().padLeft(2, '0')}'
        '${birthDate.day.toString().padLeft(2, '0')}';
  }

  /// Create a copy with modified fields
  SmUserProfile copyWith({
    double? heightCm,
    double? weightKg,
    Gender? gender,
    DateTime? birthDate,
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
