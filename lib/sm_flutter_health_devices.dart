/// sm_flutter_health_devices - Unified Flutter plugin for health devices
///
/// Wraps sm_fitrus, sm_lepu, and sm_omron plugins into a single API
/// with permission management and unified event streaming.
library sm_flutter_health_devices;

// Main plugin class
export 'src/sm_health_devices.dart';

// Models
export 'src/models/enums.dart';
export 'src/models/health_event_data.dart';
export 'src/models/health_vital_result.dart';
export 'src/models/user_profile.dart';

// Permission manager
export 'src/permission_manager.dart';

// Adapters (for advanced usage)
// Adapters (for advanced usage)
export 'src/adapters/fitrus_adapter.dart';
export 'src/adapters/lepu_adapter.dart';
export 'src/adapters/omron_adapter.dart';
// Export Omron plugin for direct access with correct prefix
export 'package:sm_omron/sm_omron.dart' hide Gender, TemperatureUnit;

// UI Components
export 'src/ui/sm_device_config.dart';
export 'src/ui/sm_health_device_widget.dart';
