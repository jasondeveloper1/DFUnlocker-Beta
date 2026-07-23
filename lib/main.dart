import 'package:flutter/material.dart';
import 'constants/app_branding.dart';
import 'screens/access_key_screen.dart';
import 'services/device_connection_controller.dart';
import 'services/phone_specs_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhoneSpecsService.instance.warmUp();
  DeviceConnectionController.instance.start();
  runApp(const DFUUnlockerBetaApp());
}

class DFUUnlockerBetaApp extends StatelessWidget {
  const DFUUnlockerBetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AccessKeyScreen(),
    );
  }
}
