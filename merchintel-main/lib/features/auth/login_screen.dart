import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/settings.dart';
import '../home/home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _setupStore() async {
    final storeName = _storeNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final pin = _pinController.text.trim();

    if (storeName.isEmpty || ownerName.isEmpty || pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    final settingsBox = Hive.box<AppSettings>('settings');
    final settings = settingsBox.get(0) ?? AppSettings();
    settings.storeName = storeName;
    settings.ownerName = ownerName;
    settings.pin = pin;
    await settingsBox.put(0, settings);

    if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeShell(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Shelf Intelligence',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Offline-first shelf & stock insights',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),

              const SizedBox(height: 28),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _field('Store Name', _storeNameController),
                      _field('Owner Name', _ownerNameController),
                      _pinField(_pinController),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                '🟢 Offline Ready · Data stored on this device',
                style: TextStyle(fontSize: 12),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _setupStore,
                  child: const Text('Set Up Store'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------- Widgets --------

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _pinField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        decoration: InputDecoration(
          labelText: '4-digit PIN',
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
