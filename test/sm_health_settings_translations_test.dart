import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';
import 'package:sm_omron/sm_omron.dart' as omron;

void main() {
  test('defaults settings language to English', () {
    const config = SmHealthInitConfig();
    final translations = SmHealthSettingsTranslations(config.lang);

    expect(translations.languageCode, 'en');
    expect(translations.textDirection, TextDirection.ltr);
    expect(translations.measurementSettings, 'Measurement Settings');
    expect(translations.measurementType(MeasurementType.weight), 'Weight');
    expect(translations.provider(DeviceProvider.omron), 'Omron');
  });

  test('provides Arabic settings translations and RTL direction', () {
    const translations =
        SmHealthSettingsTranslations(SmHealthSettingsLanguage.ar);

    expect(translations.languageCode, 'ar');
    expect(translations.textDirection, TextDirection.rtl);
    expect(translations.measurementSettings, 'إعدادات القياسات');
    expect(translations.measurementType(MeasurementType.weight), 'الوزن');
    expect(translations.provider(DeviceProvider.omron), 'أومرون');
    expect(
      translations.omronStatus(omron.OmronConnectionState.transferring),
      'جارٍ نقل البيانات...',
    );
  });
}
