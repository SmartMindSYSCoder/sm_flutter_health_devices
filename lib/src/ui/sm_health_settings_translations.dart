import 'package:flutter/widgets.dart';
import 'package:sm_omron/sm_omron.dart' as omron;

import '../models/enums.dart';

/// English and Arabic text used by the health settings pages.
///
/// Use `ar` for Arabic. Any other language code falls back to English.
class SmHealthSettingsTranslations {
  final String languageCode;

  const SmHealthSettingsTranslations._(this.languageCode);

  factory SmHealthSettingsTranslations.forLanguage(String languageCode) {
    return SmHealthSettingsTranslations._(
      languageCode.toLowerCase() == 'ar' ? 'ar' : 'en',
    );
  }

  bool get isArabic => languageCode == 'ar';

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
      case omron.OmronConnectionState.disconnecting:
        return isArabic ? 'جارٍ قطع الاتصال...' : 'Disconnecting...';
      case omron.OmronConnectionState.disconnected:
        return isArabic ? 'تم قطع الاتصال.' : 'Disconnected.';
      case omron.OmronConnectionState.idle:
        return isArabic ? 'خامل.' : 'Idle.';
      default:
        return state.statusMessage;
    }
  }
}
