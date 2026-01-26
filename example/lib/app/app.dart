import 'package:flutter/material.dart';
import 'theme.dart';
import '../pages/demo_usage_page.dart';

class HealthDevicesApp extends StatelessWidget {
  const HealthDevicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Devices Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const DemoUsagePage(),
    );
  }
}
