import 'package:flutter/widgets.dart';
import 'package:sm_omron/sm_omron.dart' as omron;

import '../models/enums.dart';

/// Supported languages for the health settings pages.
enum SmHealthSettingsLanguage {
  en,
  ar,
}

/// English and Arabic text used by the health settings pages.
class SmHealthSettingsTranslations {
  final SmHealthSettingsLanguage language;

  const SmHealthSettingsTranslations(this.language);

  String get languageCode => language.name;

  bool get isArabic => language == SmHealthSettingsLanguage.ar;

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String get measurementSettings =>
      isArabic ? 'إعدادات القياسات' : 'Measurement Settings';
  String get resetToDefaults =>
      isArabic ? 'إعادة ضبط الإعدادات' : 'Reset to Defaults';
  String get preferences => isArabic ? 'التفضيلات' : 'Preferences';
  String get omronDevices => isArabic ? 'أجهزة أومرون' : 'Omron Devices';
  String get managePairedEquipment =>
      isArabic ? 'إدارة أجهزتك المقترنة' : 'Manage your paired equipment';
  String get preferredProvider =>
      isArabic ? 'مزود الجهاز المفضل' : 'PREFERRED PROVIDER';
  String get testMeasurement =>
      isArabic ? 'اختبار القياس' : 'Test Measurement';
  String get testDevice => isArabic ? 'اختبار الجهاز' : 'Test Device';
  String testTypeMeasurement(MeasurementType type) => isArabic
      ? 'اختبار قياس ${measurementType(type)}'
      : 'Test ${measurementType(type)} Measurement';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get measurementSuccess =>
      isArabic ? 'تم إكمال القياس بنجاح' : 'Measurement Successful';
  String get resetToDefaultsQuestion =>
      isArabic ? 'إعادة ضبط الإعدادات؟' : 'Reset to Defaults?';
  String get resetToDefaultsDescription => isArabic
      ? 'سيؤدي هذا إلى إعادة جميع مزودي الأجهزة المفضلين إلى القيم الافتراضية.'
      : 'This will reset all your preferred device providers to their default values.';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get reset => isArabic ? 'إعادة ضبط' : 'Reset';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get remove => isArabic ? 'إزالة' : 'Remove';
  String get removeDevice => isArabic ? 'إزالة الجهاز' : 'Remove device';
  String get removeDeviceQuestion =>
      isArabic ? 'إزالة الجهاز؟' : 'Remove Device?';
  String removeDeviceDescription(String? deviceName) => isArabic
      ? 'سيؤدي هذا إلى إلغاء اقتران ${deviceName ?? unknownDevice} وإزالته من أجهزتك المحفوظة.'
      : 'This will unpair and remove ${deviceName ?? unknownDevice} from your saved devices.';
  String get addNewDevice => isArabic ? 'إضافة جهاز جديد' : 'Add New Device';
  String get pairNewDevice => isArabic ? 'إقران جهاز جديد' : 'Pair New Device';
  String get selectOmronDevice =>
      isArabic ? 'اختر جهاز أومرون' : 'Select Omron Device';
  String get noDevicesYet => isArabic ? 'لا توجد أجهزة بعد' : 'No Devices Yet';
  String get noDevicesAvailable =>
      isArabic ? 'لا توجد أجهزة متاحة' : 'No devices available';
  String get connectOmronEquipment => isArabic
      ? 'قم بتوصيل جهاز أومرون الصحي لبدء متابعة قياساتك الحيوية.'
      : 'Connect your Omron health equipment to start tracking your vitals.';
  String get yourEquipment => isArabic ? 'أجهزتك' : 'YOUR EQUIPMENT';
  String get unknownDevice => isArabic ? 'جهاز غير معروف' : 'Unknown Device';
  String get notAvailable => isArabic ? 'غير متاح' : 'N/A';
  String serialNumber(String value) =>
      isArabic ? 'الرقم التسلسلي: $value' : 'SN: $value';

  String get bluetoothPermissionRequired => isArabic
      ? 'يلزم منح إذن البلوتوث للبحث عن الأجهزة.'
      : 'Bluetooth permission is required to scan for devices.';
  String get enableBluetooth => isArabic
      ? 'يرجى تشغيل البلوتوث للبحث عن الأجهزة.'
      : 'Please turn on Bluetooth to scan for devices.';
  String get locationPermissionRequired => isArabic
      ? 'يلزم منح إذن الموقع للبحث عن أجهزة البلوتوث منخفض الطاقة.'
      : 'Location permission is required to scan for BLE devices.';
  String get enableLocation => isArabic
      ? 'يرجى تشغيل خدمات الموقع للبحث عن أجهزة البلوتوث منخفض الطاقة.'
      : 'Please enable Location services to scan for BLE devices.';
  String get starting => isArabic ? 'جارٍ البدء...' : 'Starting...';
  String get processing => isArabic ? 'جارٍ المعالجة...' : 'Processing...';
  String configuring(String modelName) =>
      isArabic ? 'جارٍ إعداد $modelName' : 'Configuring $modelName';
  String scanningFor(String? modelName) =>
      isArabic ? 'جارٍ البحث عن $modelName...' : 'Scanning for $modelName...';
  String pairingWith(String? modelName) => isArabic
      ? 'جارٍ الاقتران مع $modelName...'
      : 'Pairing with $modelName...';
  String get pairingFailed => isArabic
      ? 'فشل الاقتران. يرجى المحاولة مرة أخرى.'
      : 'Pairing failed. Please try again.';
  String get deviceAddedSuccessfully =>
      isArabic ? 'تمت إضافة الجهاز بنجاح!' : 'Device added successfully!';
  String get deviceNotFound => isArabic
      ? 'لم يتم العثور على الجهاز. تأكد من أنه في وضع الاقتران.'
      : 'Device not found. Ensure it is in pairing mode.';
  String errorAddingDevice(Object error) => isArabic
      ? 'حدث خطأ أثناء إضافة الجهاز: $error'
      : 'Error adding device: $error';
  String errorLoadingDevices(Object error) => isArabic
      ? 'حدث خطأ أثناء تحميل الأجهزة: $error'
      : 'Error loading devices: $error';

  String get stopMeasurementQuestion =>
      isArabic ? 'إيقاف القياس؟' : 'Stop Measurement?';
  String get stopMeasurementDescription => isArabic
      ? 'هل أنت تأكد من أنك تريد إلغاء القياس الحالي؟'
      : 'Are you sure you want to cancel the current measurement?';
  String get continueAction => isArabic ? 'متابعة' : 'Continue';
  String get stopAction => isArabic ? 'إيقاف' : 'Stop';
  String get initFailed => isArabic
      ? 'فشل في تهيئة نظام الأجهزة الصحية. يرجى إعادة تشغيل التطبيق.'
      : 'Failed to initialize health device system. Please restart the app.';
  String get fitrusProfileRequired => isArabic
      ? 'يتطلب جهاز فيترس بيانات الملف الشخصي ومفتاح API لقياس تكوين الجسم.'
      : 'Fitrus requires user profile data and API key for body composition.';
  String get unsupportedOmronType => isArabic
      ? 'نوع القياس غير مدعوم لأجهزة أومرون.'
      : 'Unsupported measurement type for Omron.';
  String unsupportedMeasurementType(MeasurementType type) => isArabic
      ? 'نوع القياس غير مدعوم لهذا الوجت: ${measurementType(type)}'
      : 'Unsupported measurement type for this widget: ${type.displayName}';
  String get unknownError => isArabic ? 'حدث خطأ' : 'An error occurred';

  String get requiredPermissionsAndServices =>
      isArabic ? 'الأذونات والخدمات المطلوبة' : 'Required Permissions & Services';
  String get permissionsAndServicesDescription => isArabic
      ? 'يرجى منح الأذونات وتفعيل الخدمات التالية لبدء القياس.'
      : 'Please grant permissions and enable services below to start measurement.';
  String get bluetoothPermission =>
      isArabic ? 'إذن البلوتوث' : 'Bluetooth Permission';
  String get locationPermission =>
      isArabic ? 'إذن الموقع' : 'Location Permission';
  String get bluetoothAdapter =>
      isArabic ? 'تشغيل البلوتوث' : 'Bluetooth Service';
  String get locationService =>
      isArabic ? 'خدمات الموقع (GPS)' : 'Location Services (GPS)';
  String get granted => isArabic ? 'ممنوح' : 'Granted';
  String get enabled => isArabic ? 'مفعل' : 'Enabled';
  String get disabled => isArabic ? 'معطل' : 'Disabled';
  String get denied => isArabic ? 'مرفوض' : 'Denied';
  String get grantPermission => isArabic ? 'منح الإذن' : 'Grant Permission';
  String get turnOn => isArabic ? 'تشغيل' : 'Turn On';
  String get openSettings => isArabic ? 'فتح الإعدادات' : 'Open Settings';
  String get grantAndEnableAll =>
      isArabic ? 'منح وتفعيل الكل' : 'Grant & Enable All';
  String get checkAgain => isArabic ? 'إعادة التحديث' : 'Check Again';
  String get allRequirementsMet =>
      isArabic ? 'تم تلبية جميع المتطلبات' : 'All Requirements Met';

  /// Dynamically translates status, error, and scanning messages into clear,
  /// user-friendly, localized strings. Sanitizes raw technical error codes.
  String translateMessage(String? message, {MeasurementType? measurementType}) {
    if (message == null || message.trim().isEmpty) {
      return starting;
    }

    final trimmed = message.trim();
    final lower = trimmed.toLowerCase();

    // 1. Sanitize raw GATT, BLE, numeric, or SDK technical error codes
    if (lower.contains('gatt') ||
        lower.contains('0x') ||
        lower.contains('exception') ||
        lower.contains('error code') ||
        lower.contains('status_') ||
        lower.contains('blestate') ||
        lower.contains('icble') ||
        lower.contains('icdevice') ||
        lower.contains('icscale') ||
        RegExp(r'^\d+$').hasMatch(trimmed)) {
      return isArabic
          ? 'حدث خطأ أثناء الاتصال بالجهاز. يرجى التأكد من تشغيل الجهاز وقربه ثم المحاولة مرة أخرى.'
          : 'Device connection error. Please ensure your device is powered on, nearby, and try again.';
    }

    // 2. Omron SDK internal errors
    if (lower.contains('omron') && lower.contains('error')) {
      return isArabic
          ? 'خطأ في تواصل جهاز أومرون. يرجى التأكد من وضع الاقتران وإعادة المحاولة.'
          : 'Omron device error. Please ensure the device is in pairing mode and retry.';
    }

    // 3. Scanning / Searching for devices
    if (lower.startsWith('scanning') ||
        lower.contains('searching for device') ||
        lower == 'status: scanning') {
      return isArabic
          ? 'جارٍ البحث عن جهازك... يرجى التأكد من تشغيل الجهاز.'
          : 'Searching for your device... Please ensure device is powered on.';
    }

    // 4. Connecting / Discovering Services
    if (lower.startsWith('connecting') ||
        lower.contains('connecting to device') ||
        lower == 'status: connecting' ||
        lower.contains('discoveringservices')) {
      return isArabic
          ? 'جارٍ الاتصال بالجهاز... يرجى إبقاء الجهاز قريباً.'
          : 'Connecting to device... Please keep the device nearby.';
    }

    // 5. Connected / Finalizing / Data Available
    if (lower == 'connected' ||
        lower == 'connected! finalizing...' ||
        lower == 'status: connected' ||
        lower.contains('dataavailable')) {
      return isArabic
          ? 'تم الاتصال بالجهاز بنجاح! جارٍ تجهيز البيانات...'
          : 'Connected successfully! Finalizing data...';
    }

    // 6. Transferring / Recording
    if (lower.startsWith('transferring')) {
      return isArabic
          ? 'جارٍ نقل البيانات من الجهاز...'
          : 'Transferring data from device...';
    }
    if (lower.startsWith('recording')) {
      return isArabic
          ? 'جارٍ تسجيل البيانات...'
          : 'Recording vital data...';
    }

    // 7. Lepu Scale / Weight Specific Messages (including ICBleState)
    if (lower.contains('icblestatepoweredon') ||
        lower.contains('icblestateon') ||
        lower.contains('icblestate')) {
      if (lower.contains('poweredoff') || lower.contains('off')) {
        return enableBluetooth;
      }
      return isArabic
          ? 'الميزان جاهز! يرجى الوقوف على الميزان حافي القدمين والثبات.'
          : 'Scale is ready! Please step onto the scale barefoot and stand still.';
    }
    if (lower.contains('step onto the scale') ||
        lower.contains('step on scale') ||
        lower.contains('stand on scale') ||
        lower.contains('scale ready')) {
      return isArabic
          ? 'الميزان جاهز! يرجى الوقوف على الميزان حافي القدمين والثبات.'
          : 'Scale is ready! Please step onto the scale barefoot and stand still.';
    }
    if (lower.contains('impedance') || lower.contains('fat measuring')) {
      return isArabic
          ? 'جارٍ قياس نسبة الدهون وتكوين الجسم... يرجى الثبات حافي القدمين على الحساسات.'
          : 'Measuring body fat and composition... Please stand barefoot on scale sensors.';
    }
    if (lower.contains('unstable')) {
      return isArabic
          ? 'جارٍ ضبط القياس... يرجى الوقوف ثابتاً دون اهتزاز.'
          : 'Stabilizing weight... Please stand still on the scale without moving.';
    }
    if (lower.startsWith('measuring weight:')) {
      final weightVal = trimmed.replaceFirst(RegExp(r'^[Mm]easuring weight:\s*'), '');
      return isArabic
          ? 'جارٍ قياس الوزن: $weightVal (يرجى الثبات)'
          : 'Measuring weight: $weightVal (Please stand still)';
    }
    if (lower.contains('icomon') || lower.contains('scale connected')) {
      return isArabic
          ? 'تم الاتصال بالميزان! يرجى الوقوف على الميزان.'
          : 'Scale connected! Please step onto the scale.';
    }

    // 8. Measuring (Contextual based on measurement type)
    if (lower == 'measuring...' || lower == 'measuring') {
      if (measurementType == MeasurementType.bloodPressure) {
        return isArabic
            ? 'جارٍ قياس ضغط الدم... يرجى البقاء ثابتاً.'
            : 'Measuring blood pressure... Please remain still.';
      } else if (measurementType == MeasurementType.temperature) {
        return isArabic
            ? 'جارٍ قياس درجة الحرارة... يرجى عدم التحرك.'
            : 'Measuring temperature... Please hold position.';
      } else if (measurementType == MeasurementType.weight ||
          measurementType == MeasurementType.bodyComposition) {
        return isArabic
            ? 'جارٍ قياس الوزن وتكوين الجسم... يرجى الوقوف ثابتاً.'
            : 'Measuring weight and body composition... Please stand still.';
      } else if (measurementType == MeasurementType.spo2) {
        return isArabic
            ? 'جارٍ قياس نسبة الأكسجين... يرجى عدم التحرك.'
            : 'Measuring oxygen level... Please remain still.';
      }
      return isArabic
          ? 'جارٍ إجراء القياس... يرجى البقاء ثابتاً.'
          : 'Measuring... Please remain still.';
    }

    if (lower.startsWith('measuring...')) {
      if (isArabic) {
        return trimmed
            .replaceAll('Measuring...', 'جارٍ القياس...')
            .replaceAll('mmHg', 'مم زئبق');
      }
      return trimmed;
    }

    // 8. Disconnecting / Disconnected
    if (lower.startsWith('disconnecting') || lower == 'status: disconnecting') {
      return isArabic ? 'جارٍ قطع الاتصال...' : 'Disconnecting...';
    }
    if (lower == 'disconnected.' ||
        lower == 'disconnected' ||
        lower == 'status: disconnected') {
      return isArabic ? 'تم قطع الاتصال بالجهاز.' : 'Disconnected from device.';
    }

    // 9. Status: scanFailed
    if (lower == 'status: scanfailed' || lower == 'scan failed') {
      return isArabic
          ? 'لم يتم العثور على الجهاز. يرجى التأكد من تشغيله وإعادة المحاولة.'
          : 'Device scan failed. Please verify the device is powered on and retry.';
    }

    // 10. Timeouts
    if (lower.contains('measurement timed out') ||
        lower.contains('timed out') ||
        lower.contains('timeout')) {
      final secondsMatch = RegExp(r'\d+').firstMatch(trimmed);
      if (secondsMatch != null) {
        return isArabic
            ? 'انتهت المهلة الزمانية للقياس بعد ${secondsMatch.group(0)} ثانية. يرجى إعادة المحاولة.'
            : 'Measurement timed out after ${secondsMatch.group(0)} seconds. Please try again.';
      }
      return isArabic
          ? 'انتهت المهلة الزمانية للقياس. يرجى إعادة المحاولة.'
          : 'Measurement timed out. Please try again.';
    }

    // 11. Bluetooth / Location Permissions & Services
    if (lower.contains('bluetooth permission')) {
      return bluetoothPermissionRequired;
    }
    if (lower.contains('location permission')) {
      return locationPermissionRequired;
    }
    if (lower.contains('bluetooth is disabled') ||
        lower.contains('turn on bluetooth')) {
      return enableBluetooth;
    }
    if (lower.contains('location service is disabled') ||
        lower.contains('enable location')) {
      return enableLocation;
    }
    if (lower.contains('failed to initialize health device system')) {
      return initFailed;
    }
    if (lower.contains('fitrus requires user profile')) {
      return fitrusProfileRequired;
    }
    if (lower.contains('unsupported measurement type for omron')) {
      return unsupportedOmronType;
    }
    if (lower.contains('unsupported measurement type for this widget')) {
      return isArabic
          ? 'نوع القياس غير مدعوم لهذا الوجت.'
          : 'Unsupported measurement type for this widget.';
    }
    if (lower.contains('pairing failed')) {
      return pairingFailed;
    }
    if (lower.contains('device not found')) {
      return deviceNotFound;
    }

    // 12. Errors prefix mapping
    if (trimmed.startsWith('Pairing error:')) {
      return isArabic
          ? trimmed.replaceFirst('Pairing error:', 'خطأ في الاقتران:')
          : trimmed;
    }
    if (trimmed.startsWith('Omron flow error:')) {
      return isArabic
          ? trimmed.replaceFirst('Omron flow error:', 'خطأ في أجهزة أومرون:')
          : trimmed;
    }
    if (trimmed.startsWith('Error adding device:')) {
      return isArabic
          ? trimmed.replaceFirst('Error adding device:', 'حدث خطأ أثناء إضافة الجهاز:')
          : trimmed;
    }
    if (trimmed.startsWith('Error loading devices:')) {
      return isArabic
          ? trimmed.replaceFirst('Error loading devices:', 'حدث خطأ أثناء تحميل الأجهزة:')
          : trimmed;
    }
    if (trimmed.startsWith('Scan error:')) {
      return isArabic
          ? trimmed.replaceFirst('Scan error:', 'خطأ في البحث عن الجهاز:')
          : trimmed;
    }
    if (trimmed.startsWith('Connection error:')) {
      return isArabic
          ? trimmed.replaceFirst('Connection error:', 'خطأ في الاتصال:')
          : trimmed;
    }
    if (lower.contains('user cancelled') || lower.contains('cancelled')) {
      return isArabic ? 'تم إلغاء العملية.' : 'Operation cancelled.';
    }
    if (lower.contains('connection lost') || lower.contains('connection failed')) {
      return isArabic
          ? 'فشل الاتصال بالجهاز. يرجى التأكد من تشغيله ثم إعادة المحاولة.'
          : 'Connection failed. Please ensure your device is powered on and retry.';
    }
    if (lower.contains('measurement failed')) {
      return isArabic
          ? 'فشل إجراء القياس. يرجى محاولة القياس مرة أخرى.'
          : 'Measurement failed. Please try again.';
    }
    if (trimmed == 'An error occurred' || trimmed == 'Error') {
      return unknownError;
    }

    if (!isArabic) return message;
    return message;
  }

  String measurementType(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight:
        return isArabic ? 'الوزن' : 'Weight';
      case MeasurementType.bloodPressure:
        return isArabic ? 'ضغط الدم' : 'Blood Pressure';
      case MeasurementType.temperature:
        return isArabic ? 'درجة الحرارة' : 'Temperature';
      case MeasurementType.spo2:
        return isArabic ? 'تشبع الأكسجين' : 'SpO2';
      case MeasurementType.bodyComposition:
        return isArabic ? 'تكوين الجسم' : 'Body Composition';
      case MeasurementType.activity:
        return isArabic ? 'النشاط' : 'Activity';
      case MeasurementType.wheeze:
        return isArabic ? 'الصفير التنفسي' : 'Wheeze';
      case MeasurementType.glucometer:
        return isArabic ? 'سكر الدم' : 'Blood Glucose';
      case MeasurementType.height:
        return isArabic ? 'الطول' : 'Height';
      case MeasurementType.unknown:
        return isArabic ? 'غير معروف' : 'Unknown';
    }
  }

  String provider(DeviceProvider provider) {
    switch (provider) {
      case DeviceProvider.omron:
        return isArabic ? 'أومرون' : 'Omron';
      case DeviceProvider.lepu:
        return isArabic ? 'ليبو ميديكال' : 'Lepu Medical';
      case DeviceProvider.fitrus:
        return isArabic ? 'فيترس' : 'Fitrus';
      case DeviceProvider.accucheck:
        return isArabic ? 'أكيوتشيك' : 'AccuChek';
      case DeviceProvider.raycome:
        return isArabic ? 'رايكوم' : 'Raycome';
      case DeviceProvider.unknown:
        return isArabic ? 'غير معروف' : 'Unknown';
    }
  }

  String omronStatus(omron.OmronConnectionState state) {
    switch (state) {
      case omron.OmronConnectionState.scanning:
        return isArabic ? 'جارٍ البحث عن جهاز...' : 'Searching for device...';
      case omron.OmronConnectionState.connecting:
        return isArabic ? 'جارٍ الاتصال...' : 'Connecting...';
      case omron.OmronConnectionState.connected:
        return isArabic
            ? 'تم الاتصال، جارٍ الإنهاء...'
            : 'Connected! Finalizing...';
      case omron.OmronConnectionState.transferring:
        return isArabic ? 'جارٍ نقل البيانات...' : 'Transferring data...';
      case omron.OmronConnectionState.recording:
        return isArabic ? 'جارٍ التسجيل...' : 'Recording...';
      case omron.OmronConnectionState.disconnecting:
        return isArabic ? 'جارٍ قطع الاتصال...' : 'Disconnecting...';
      case omron.OmronConnectionState.disconnected:
        return isArabic ? 'تم قطع الاتصال.' : 'Disconnected.';
      case omron.OmronConnectionState.idle:
        return isArabic ? 'جاهز.' : 'Ready.';
      case omron.OmronConnectionState.error:
        return isArabic ? 'خطأ.' : 'Error.';
    }
  }
}
