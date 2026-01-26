import 'enums.dart';

/// Unified vital result model for all health measurements
/// Covers data from all three plugins: sm_fitrus, sm_lepu, sm_omron
class HealthVitalResult {
  // === Common Fields ===

  /// Device provider that generated this result
  final DeviceProvider provider;

  /// Type of measurement
  final MeasurementType measurementType;

  /// Date/time of measurement
  final DateTime? measurementDate;

  /// Whether this result contains valid data
  final bool hasData;

  /// Error message if any
  final String? errorMessage;

  // === Weight Fields (Lepu, Omron) ===

  /// Weight in kilograms
  final double? weight;

  /// Body Mass Index
  final double? bmi;

  // === Blood Pressure Fields (Lepu, Omron) ===

  /// Systolic blood pressure in mmHg
  final int? systolic;

  /// Diastolic blood pressure in mmHg
  final int? diastolic;

  /// Pulse rate in BPM
  final int? pulse;

  /// Irregular heartbeat detected
  final bool? irregularHeartbeat;

  // === Temperature Fields (Lepu, Omron) ===

  /// Body temperature
  final double? temperature;

  /// Temperature unit (Celsius/Fahrenheit)
  final TemperatureUnit temperatureUnit;

  // === SpO2 Fields (Lepu, Omron) ===

  /// Blood oxygen saturation percentage (0-100)
  final int? spo2;

  /// Heart rate in BPM
  final int? heartRate;

  // === Body Composition Fields (Fitrus) ===

  /// Body fat percentage
  final double? fatPercentage;

  /// Body fat mass in kg
  final double? fatMass;

  /// Muscle mass in kg
  final double? muscleMass;

  /// Skeletal muscle mass in kg (Fitrus specific)
  final double? skeletalMuscleMass;

  /// Water percentage
  final double? waterPercentage;

  /// Basal Metabolic Rate in kcal
  final double? bmr;

  /// Minerals in kg
  final double? minerals;

  /// Protein in kg
  final double? protein;

  /// Calorie
  final double? calorie;

  // === Activity Fields (Omron) ===

  /// Number of steps
  final int? steps;

  /// Aerobic steps
  final int? aerobicSteps;

  /// Distance in meters
  final double? distance;

  /// Calories burned
  final int? calories;

  // === Omron Extended Fields ===

  /// Body fat percentage (Omron weight scale)
  final double? bodyFatPercentage;

  /// Skeletal muscle percentage
  final double? skeletalMusclePercentage;

  /// Visceral fat level
  final int? visceralFatLevel;

  /// Basal metabolic rate (int version from Omron)
  final int? basalMetabolicRate;

  /// Body age
  final int? bodyAge;

  /// Wheeze result
  final bool? wheezeDetected;

  // === Glucometer Fields (AccuChek) ===

  // === Glucometer Fields (AccuChek) ===

  /// Blood glucose level in mg/dL
  final int? glucoseLevel;

  // === Height Fields ===

  /// Height in cm
  final double? height;

  /// Raw data from the device (for debugging)
  final dynamic rawData;

  const HealthVitalResult({
    required this.provider,
    required this.measurementType,
    this.measurementDate,
    this.hasData = true,
    this.errorMessage,
    // Weight
    this.weight,
    this.bmi,
    // Blood Pressure
    this.systolic,
    this.diastolic,
    this.pulse,
    this.irregularHeartbeat,
    // Temperature
    this.temperature,
    this.temperatureUnit = TemperatureUnit.celsius,
    // SpO2
    this.spo2,
    this.heartRate,
    // Body Composition
    this.fatPercentage,
    this.fatMass,
    this.muscleMass,
    this.skeletalMuscleMass,
    this.waterPercentage,
    this.bmr,
    this.minerals,
    this.protein,
    this.calorie,
    // Activity
    this.steps,
    this.aerobicSteps,
    this.distance,
    this.calories,
    // Omron extended
    this.bodyFatPercentage,
    this.skeletalMusclePercentage,
    this.visceralFatLevel,
    this.basalMetabolicRate,
    this.bodyAge,
    this.wheezeDetected,
    // Glucometer
    this.glucoseLevel,
    // Height
    this.height,
    this.rawData,
  });

  /// Create an error result
  factory HealthVitalResult.error({
    required DeviceProvider provider,
    required MeasurementType measurementType,
    required String message,
  }) {
    return HealthVitalResult(
      provider: provider,
      measurementType: measurementType,
      hasData: false,
      errorMessage: message,
    );
  }

  /// Create an empty result (no data yet)
  factory HealthVitalResult.empty({
    required DeviceProvider provider,
    required MeasurementType measurementType,
  }) {
    return HealthVitalResult(
      provider: provider,
      measurementType: measurementType,
      hasData: false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'measurementType': measurementType.name,
        'measurementDate': measurementDate?.toIso8601String(),
        'hasData': hasData,
        'errorMessage': errorMessage,
        // Weight
        'weight': weight,
        'bmi': bmi,
        // Blood Pressure
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'irregularHeartbeat': irregularHeartbeat,
        // Temperature
        'temperature': temperature,
        'temperatureUnit': temperatureUnit.name,
        // SpO2
        'spo2': spo2,
        'heartRate': heartRate,
        // Body Composition
        'fatPercentage': fatPercentage,
        'fatMass': fatMass,
        'muscleMass': muscleMass,
        'skeletalMuscleMass': skeletalMuscleMass,
        'waterPercentage': waterPercentage,
        'bmr': bmr,
        'minerals': minerals,
        'protein': protein,
        'calorie': calorie,
        // Activity
        'steps': steps,
        'aerobicSteps': aerobicSteps,
        'distance': distance,
        'calories': calories,
        // Omron extended
        'bodyFatPercentage': bodyFatPercentage,
        'skeletalMusclePercentage': skeletalMusclePercentage,
        'visceralFatLevel': visceralFatLevel,
        'basalMetabolicRate': basalMetabolicRate,
        'bodyAge': bodyAge,
        'wheezeDetected': wheezeDetected,
        // Glucometer
        'glucoseLevel': glucoseLevel,
        // Height
        'height': height,
      };

  @override
  String toString() {
    final buffer = StringBuffer('HealthVitalResult(');
    buffer.write('provider: ${provider.displayName}, ');
    buffer.write('type: ${measurementType.displayName}');

    switch (measurementType) {
      case MeasurementType.weight:
        if (weight != null) buffer.write(', weight: ${weight}kg');
        if (bmi != null) buffer.write(', bmi: $bmi');
        break;
      case MeasurementType.bloodPressure:
        if (systolic != null && diastolic != null) {
          buffer.write(', bp: $systolic/$diastolic mmHg');
        }
        if (pulse != null) buffer.write(', pulse: $pulse bpm');
        break;
      case MeasurementType.temperature:
        if (temperature != null) {
          buffer.write(', temp: $temperature${temperatureUnit.symbol}');
        }
        break;
      case MeasurementType.spo2:
        if (spo2 != null) buffer.write(', spo2: $spo2%');
        if (heartRate != null) buffer.write(', hr: $heartRate bpm');
        break;
      case MeasurementType.bodyComposition:
        if (fatPercentage != null) buffer.write(', fat: $fatPercentage%');
        if (muscleMass != null) buffer.write(', muscle: ${muscleMass}kg');
        break;
      case MeasurementType.activity:
        if (steps != null) buffer.write(', steps: $steps');
        if (calories != null) buffer.write(', cal: $calories');
        break;
      case MeasurementType.wheeze:
        if (wheezeDetected != null) {
          buffer.write(', wheeze: ${wheezeDetected! ? "detected" : "none"}');
        }
        break;
      case MeasurementType.glucometer:
        if (glucoseLevel != null) {
          buffer.write(', glucose: $glucoseLevel mg/dL');
        }
        break;
      case MeasurementType.height:
        if (height != null) buffer.write(', height: ${height}cm');
        break;
      case MeasurementType.unknown:
        break;
    }

    buffer.write(')');
    return buffer.toString();
  }

  /// Copy with modified fields
  HealthVitalResult copyWith({
    DeviceProvider? provider,
    MeasurementType? measurementType,
    DateTime? measurementDate,
    bool? hasData,
    String? errorMessage,
    double? weight,
    double? bmi,
    int? systolic,
    int? diastolic,
    int? pulse,
    bool? irregularHeartbeat,
    double? temperature,
    TemperatureUnit? temperatureUnit,
    int? spo2,
    int? heartRate,
    double? fatPercentage,
    double? fatMass,
    double? muscleMass,
    double? waterPercentage,
    double? bmr,
    double? minerals,
    double? protein,
    double? calorie,
    int? steps,
    int? aerobicSteps,
    double? distance,
    int? calories,
    double? bodyFatPercentage,
    double? skeletalMusclePercentage,
    int? visceralFatLevel,
    int? basalMetabolicRate,
    int? bodyAge,
    bool? wheezeDetected,
    int? glucoseLevel,
    double? height,
    dynamic rawData,
  }) {
    return HealthVitalResult(
      provider: provider ?? this.provider,
      measurementType: measurementType ?? this.measurementType,
      measurementDate: measurementDate ?? this.measurementDate,
      hasData: hasData ?? this.hasData,
      errorMessage: errorMessage ?? this.errorMessage,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      irregularHeartbeat: irregularHeartbeat ?? this.irregularHeartbeat,
      temperature: temperature ?? this.temperature,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      spo2: spo2 ?? this.spo2,
      heartRate: heartRate ?? this.heartRate,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      fatMass: fatMass ?? this.fatMass,
      muscleMass: muscleMass ?? this.muscleMass,
      waterPercentage: waterPercentage ?? this.waterPercentage,
      bmr: bmr ?? this.bmr,
      minerals: minerals ?? this.minerals,
      protein: protein ?? this.protein,
      calorie: calorie ?? this.calorie,
      steps: steps ?? this.steps,
      aerobicSteps: aerobicSteps ?? this.aerobicSteps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      skeletalMusclePercentage:
          skeletalMusclePercentage ?? this.skeletalMusclePercentage,
      visceralFatLevel: visceralFatLevel ?? this.visceralFatLevel,
      basalMetabolicRate: basalMetabolicRate ?? this.basalMetabolicRate,
      bodyAge: bodyAge ?? this.bodyAge,
      wheezeDetected: wheezeDetected ?? this.wheezeDetected,
      glucoseLevel: glucoseLevel ?? this.glucoseLevel,
      height: height ?? this.height,
      rawData: rawData ?? this.rawData,
    );
  }
}
