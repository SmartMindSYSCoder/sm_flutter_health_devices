import 'package:flutter/material.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

/// Bottom sheet for selecting a device provider
class ProviderBottomSheet extends StatelessWidget {
  final MeasurementType measurementType;
  final void Function(DeviceProvider provider) onProviderSelected;

  const ProviderBottomSheet({
    super.key,
    required this.measurementType,
    required this.onProviderSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required MeasurementType measurementType,
    required void Function(DeviceProvider provider) onProviderSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => ProviderBottomSheet(
        measurementType: measurementType,
        onProviderSelected: (provider) {
          Navigator.pop(context);
          onProviderSelected(provider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = measurementType.supportedProviders;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Select Provider',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Choose which device to use for ${measurementType.displayName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          ...providers.map((provider) => ListTile(
                leading: CircleAvatar(
                  child: Icon(_getProviderIcon(provider)),
                ),
                title: Text(provider.displayName),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => onProviderSelected(provider),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getProviderIcon(DeviceProvider provider) {
    switch (provider) {
      case DeviceProvider.omron:
        return Icons.medical_services_outlined;
      case DeviceProvider.lepu:
        return Icons.bluetooth_connected;
      case DeviceProvider.fitrus:
        return Icons.accessibility;
      case DeviceProvider.accucheck:
        return Icons.bloodtype;
      case DeviceProvider.raycome:
        return Icons.devices;
      case DeviceProvider.unknown:
        return Icons.device_unknown;
    }
  }
}

/// Dialog for body composition input
class BodyCompositionDialog extends StatefulWidget {
  final void Function(
      double height, double weight, Gender gender, String birthDate) onStart;

  const BodyCompositionDialog({
    super.key,
    required this.onStart,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(
            double height, double weight, Gender gender, String birthDate)
        onStart,
  }) {
    return showDialog(
      context: context,
      builder: (context) => BodyCompositionDialog(onStart: onStart),
    );
  }

  @override
  State<BodyCompositionDialog> createState() => _BodyCompositionDialogState();
}

class _BodyCompositionDialogState extends State<BodyCompositionDialog> {
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  Gender _gender = Gender.male;
  DateTime _birthDate = DateTime(1990, 1, 1);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Body Composition'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _heightController,
              decoration: const InputDecoration(labelText: 'Height (cm)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.male, label: Text('Male')),
                ButtonSegment(value: Gender.female, label: Text('Female')),
              ],
              selected: {_gender},
              onSelectionChanged: (set) => setState(() => _gender = set.first),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(_formatDate(_birthDate)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Start'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _birthDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final height = double.tryParse(_heightController.text) ?? 170;
    final weight = double.tryParse(_weightController.text) ?? 70;
    final birthDate =
        '${_birthDate.year}${_birthDate.month.toString().padLeft(2, '0')}${_birthDate.day.toString().padLeft(2, '0')}';

    Navigator.pop(context);
    widget.onStart(height, weight, _gender, birthDate);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}

/// Dialog showing measurement result
class ResultDialog extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ResultDialog({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ResultDialog(
        title: title,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon, color: color, size: 48),
      title: Text(title),
      content: Text(
        value,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
