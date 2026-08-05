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

  /// Dynamically translates status, error, and scanning messages.
  String translateMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return starting;
    }
    if (!isArabic) return message;

    final trimmed = message.trim();

    // Check exact matches or common status patterns
    if (trimmed == 'Starting...' || trimmed == 'Starting') return starting;
    if (trimmed == 'Processing...' || trimmed == 'Processing') return processing;
    if (trimmed.startsWith('Scanning') ||
        trimmed.contains('searching for device') ||
        trimmed == 'Status: scanning') {
      return 'جارٍ البحث عن جهاز...';
    }
    if (trimmed.startsWith('Connecting') ||
        trimmed.contains('connecting to device') ||
        trimmed == 'Status: connecting' ||
        trimmed == 'Status: discoveringServices') {
      return 'جارٍ الاتصال...';
    }
    if (trimmed == 'Connected' ||
        trimmed == 'Connected! Finalizing...' ||
        trimmed == 'Status: connected' ||
        trimmed == 'Status: dataAvailable') {
      return 'تم الاتصال، جارٍ الإنهاء...';
    }
    if (trimmed.startsWith('Transferring')) return 'جارٍ نقل البيانات...';
    if (trimmed.startsWith('Recording')) return 'جارٍ التسجيل...';
    if (trimmed == 'Measuring...' || trimmed == 'Measuring') return 'جارٍ القياس...';
    if (trimmed.startsWith('Measuring...')) {
      return trimmed
          .replaceAll('Measuring...', 'جارٍ القياس...')
          .replaceAll('mmHg', 'مم زئبق');
    }
    if (trimmed.startsWith('Disconnecting') || trimmed == 'Status: disconnecting') {
      return 'جارٍ قطع الاتصال...';
    }
    if (trimmed == 'Disconnected.' ||
        trimmed == 'Disconnected' ||
        trimmed == 'Status: disconnected') {
      return 'تم قطع الاتصال.';
    }
    if (trimmed == 'Ready.' || trimmed == 'Ready') return 'جاهز.';
    if (trimmed == 'Completed' || trimmed == 'Measurement Successful') {
      return measurementSuccess;
    }
    if (trimmed == 'Status: scanFailed' || trimmed == 'Scan failed') {
      return 'فشل البحث عن الجهاز.';
    }

    // Errors & permissions matching
    if (trimmed.contains('Measurement timed out') ||
        trimmed.contains('timed out') ||
        trimmed.toLowerCase().contains('timeout')) {
      final secondsMatch = RegExp(r'\d+').firstMatch(trimmed);
      if (secondsMatch != null) {
        return 'انتهت المهلة الزمانية للقياس بعد ${secondsMatch.group(0)} ثانية.';
      }
      return 'انتهت المهلة الزمانية للقياس.';
    }
    if (trimmed.contains('Bluetooth permission is required')) {
      return bluetoothPermissionRequired;
    }
    if (trimmed.contains('Location permission is required')) {
      return locationPermissionRequired;
    }
    if (trimmed.contains('Bluetooth is disabled') ||
        trimmed.contains('turn on Bluetooth') ||
        trimmed.contains('Please turn on Bluetooth')) {
      return enableBluetooth;
    }
    if (trimmed.contains('Location service is disabled') ||
        trimmed.contains('enable Location') ||
        trimmed.contains('Please enable Location')) {
      return enableLocation;
    }
    if (trimmed.contains('Failed to initialize health device system')) {
      return initFailed;
    }
    if (trimmed.contains('Fitrus requires user profile data')) {
      return fitrusProfileRequired;
    }
    if (trimmed.contains('Unsupported measurement type for Omron')) {
      return unsupportedOmronType;
    }
    if (trimmed.contains('Unsupported measurement type for this widget')) {
      return 'نوع القياس غير مدعوم لهذا الوجت.';
    }
    if (trimmed.contains('Pairing failed')) {
      return pairingFailed;
    }
    if (trimmed.contains('Device not found')) {
      return deviceNotFound;
    }
    if (trimmed.startsWith('Pairing error:')) {
      return trimmed.replaceFirst('Pairing error:', 'خطأ في الاقتران:');
    }
    if (trimmed.startsWith('Omron flow error:')) {
      return trimmed.replaceFirst('Omron flow error:', 'خطأ في أجهزة أومرون:');
    }
    if (trimmed.startsWith('Error adding device:')) {
      return trimmed.replaceFirst('Error adding device:', 'حدث خطأ أثناء إضافة الجهاز:');
    }
    if (trimmed.startsWith('Error loading devices:')) {
      return trimmed.replaceFirst('Error loading devices:', 'حدث خطأ أثناء تحميل الأجهزة:');
    }
    if (trimmed.startsWith('Scan error:')) {
      return trimmed.replaceFirst('Scan error:', 'خطأ في البحث عن الجهاز:');
    }
    if (trimmed.startsWith('Connection error:')) {
      return trimmed.replaceFirst('Connection error:', 'خطأ في الاتصال:');
    }
    if (trimmed.toLowerCase().contains('user cancelled') ||
        trimmed.toLowerCase().contains('cancelled')) {
      return 'تم إلغاء العملية.';
    }
    if (trimmed.toLowerCase().contains('connection lost') ||
        trimmed.toLowerCase().contains('connection failed')) {
      return 'فشل الاتصال بالجهاز.';
    }
    if (trimmed.toLowerCase().contains('measurement failed')) {
      return 'فشل إجراء القياس.';
    }
    if (trimmed == 'An error occurred' || trimmed == 'Error') {
      return unknownError;
    }

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
