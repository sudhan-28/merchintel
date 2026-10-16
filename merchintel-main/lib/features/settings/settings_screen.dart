import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../data/product.dart';
import '../../data/settings.dart';
import 'data_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<AppSettings> _settingsBox;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box<AppSettings>('settings');
    _settings = _settingsBox.get(0) ?? AppSettings();
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put(0, _settings);
  }

  Future<void> _exportToCSV() async {
    final products = Hive.box<Product>('products').values.toList();

    List<List<dynamic>> csvData = [
      ['Name', 'Category', 'Cost Price', 'Selling Price', 'Quantity', 'Expiry Date'],
      ...products.map((product) => [
        product.name,
        product.category,
        product.costPrice,
        product.sellingPrice,
        product.quantity,
        product.expiryDate?.toString() ?? '',
      ]),
    ];

    String csv = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/products_export.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'Product Export');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Security'),
            subtitle: const Text('PIN & app protection'),
            onTap: () {
              // TODO: Implement security settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon')),
              );
            },
          ),
          const Divider(),

          ExpansionTile(
            leading: const Icon(Icons.percent),
            title: const Text('Profit Rules'),
            subtitle: const Text('Minimum margin & discounts'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Minimum Profit Margin: '),
                        Text('${_settings.minimumProfitMargin.toStringAsFixed(1)}%'),
                      ],
                    ),
                    Slider(
                      value: _settings.minimumProfitMargin,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: '${_settings.minimumProfitMargin.toStringAsFixed(1)}%',
                      onChanged: (value) {
                        setState(() {
                          _settings.minimumProfitMargin = value;
                        });
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto-discount'),
                      subtitle: const Text('Automatically apply discounts to low-margin products'),
                      value: _settings.autoDiscountEnabled,
                      onChanged: (value) {
                        setState(() {
                          _settings.autoDiscountEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),

          ExpansionTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync & Backup'),
            subtitle: const Text('Offline storage & export'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Sync'),
                      subtitle: const Text('Sync data across devices'),
                      value: _settings.syncEnabled,
                      onChanged: (value) {
                        setState(() {
                          _settings.syncEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Auto Backup'),
                      subtitle: const Text('Automatically backup data'),
                      value: _settings.backupEnabled,
                      onChanged: (value) {
                        setState(() {
                          _settings.backupEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _exportToCSV,
                      icon: const Icon(Icons.download),
                      label: const Text('Export to CSV'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DataManagementScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.storage),
                      label: const Text('Data Management'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Shelf Intelligence'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Shelf Intelligence',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 MerchIntel',
              );
            },
          ),
        ],
      ),
    );
  }
}
