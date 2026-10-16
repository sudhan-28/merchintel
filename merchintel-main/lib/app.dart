import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/settings.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/pin_verification_screen.dart';

class ShelfIntelligenceApp extends StatefulWidget {
  const ShelfIntelligenceApp({super.key});

  @override
  State<ShelfIntelligenceApp> createState() => _ShelfIntelligenceAppState();
}

class _ShelfIntelligenceAppState extends State<ShelfIntelligenceApp> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final settingsBox = Hive.box<AppSettings>('settings');
    final settings = settingsBox.get(0);

    setState(() {
      _home = (settings?.storeName != null && settings?.pin != null)
          ? const PinVerificationScreen()
          : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _home,
    );
  }
}
