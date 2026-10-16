import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../data/product.dart';
import '../../data/sale.dart';
import '../../data/settings.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  Future<void> _exportAllData() async {
    final products = Hive.box<Product>('products').values.toList();
    final sales = Hive.box<Sale>('sales').values.toList();
    final settings = Hive.box<AppSettings>('settings').get(0);

    // Export Products
    List<List<dynamic>> productCsv = [
      ['Name', 'Category', 'Cost Price', 'Selling Price', 'Quantity', 'Expiry Date'],
      ...products.map((p) => [
        p.name,
        p.category,
        p.costPrice,
        p.sellingPrice,
        p.quantity,
        p.expiryDate?.toString() ?? '',
      ]),
    ];

    // Export Sales
    List<List<dynamic>> salesCsv = [
      ['Product Name', 'Category', 'Quantity', 'Price', 'Total Amount', 'Date'],
      ...sales.map((s) => [
        s.productName,
        s.category,
        s.quantity,
        s.sellingPrice,
        s.totalAmount,
        s.timestamp.toString(),
      ]),
    ];

    // Export Settings
    List<List<dynamic>> settingsCsv = [
      ['Store Name', 'Owner Name', 'PIN', 'Min Profit Margin', 'Auto Discount', 'Sync Enabled', 'Backup Enabled'],
      [
        settings?.storeName ?? '',
        settings?.ownerName ?? '',
        settings?.pin ?? '',
        settings?.minimumProfitMargin ?? '',
        settings?.autoDiscountEnabled ?? '',
        settings?.syncEnabled ?? '',
        settings?.backupEnabled ?? '',
      ],
    ];

    // Generate Alerts
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    final sixtyDaysFromNow = now.add(const Duration(days: 60));

    final lowStockProducts = products.where((product) => product.quantity <= 5).toList();
    final highPriorityExpiry = products
        .where((product) =>
            product.expiryDate != null &&
            product.expiryDate!.isAfter(now) &&
            product.expiryDate!.isBefore(sevenDaysFromNow))
        .toList();
    final mediumPriorityExpiry = products
        .where((product) =>
            product.expiryDate != null &&
            product.expiryDate!.isAfter(sevenDaysFromNow) &&
            product.expiryDate!.isBefore(thirtyDaysFromNow))
        .toList();
    final lowPriorityExpiry = products
        .where((product) =>
            product.expiryDate != null &&
            product.expiryDate!.isAfter(thirtyDaysFromNow) &&
            product.expiryDate!.isBefore(sixtyDaysFromNow))
        .toList();
    final deadStock = products
        .where((product) =>
            product.quantity <= 2 &&
            (product.expiryDate == null || product.expiryDate!.isBefore(now)))
        .toList();

    List<List<dynamic>> alertsCsv = [
      ['Alert Type', 'Product Name', 'Details'],
      ...lowStockProducts.map((p) => ['Low Stock', p.name, '${p.quantity} remaining']),
      ...highPriorityExpiry.map((p) => ['High Priority Expiry', p.name, 'Expires ${p.expiryDate!.toString()}']),
      ...mediumPriorityExpiry.map((p) => ['Medium Priority Expiry', p.name, 'Expires ${p.expiryDate!.toString()}']),
      ...lowPriorityExpiry.map((p) => ['Low Priority Expiry', p.name, 'Expires ${p.expiryDate!.toString()}']),
      ...deadStock.map((p) => ['Dead Stock', p.name, '${p.quantity} remaining']),
    ];

    final directory = await getApplicationDocumentsDirectory();

    // Write Products
    final productFile = File('${directory.path}/products_export.csv');
    await productFile.writeAsString(const ListToCsvConverter().convert(productCsv));

    // Write Sales
    final salesFile = File('${directory.path}/sales_export.csv');
    await salesFile.writeAsString(const ListToCsvConverter().convert(salesCsv));

    // Write Settings
    final settingsFile = File('${directory.path}/settings_export.csv');
    await settingsFile.writeAsString(const ListToCsvConverter().convert(settingsCsv));

    // Write Alerts
    final alertsFile = File('${directory.path}/alerts_export.csv');
    await alertsFile.writeAsString(const ListToCsvConverter().convert(alertsCsv));

    await Share.shareXFiles([
      XFile(productFile.path),
      XFile(salesFile.path),
      XFile(settingsFile.path),
      XFile(alertsFile.path),
    ], text: 'Complete Data Export');
  }

  Future<void> _importFromCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );

    if (result != null) {
      for (PlatformFile file in result.files) {
        final content = await File(file.path!).readAsString();
        final csvData = const CsvToListConverter().convert(content);

        if (csvData.isEmpty) continue;

        final headers = csvData[0].map((e) => e.toString()).toList();

        if (headers.contains('Name') && headers.contains('Category')) {
          // Import Products
          final productBox = Hive.box<Product>('products');
          for (int i = 1; i < csvData.length; i++) {
            final row = csvData[i];
            final product = Product(
              name: row[0].toString(),
              category: row[1].toString(),
              costPrice: double.tryParse(row[2].toString()) ?? 0.0,
              sellingPrice: double.tryParse(row[3].toString()) ?? 0.0,
              quantity: int.tryParse(row[4].toString()) ?? 0,
              expiryDate: row[5].toString().isNotEmpty ? DateTime.tryParse(row[5].toString()) : null,
            );
            await productBox.add(product);
          }
        } else if (headers.contains('Product Name') && headers.contains('Category') && headers.contains('Total Amount')) {
          // Import Sales
          final salesBox = Hive.box<Sale>('sales');
          for (int i = 1; i < csvData.length; i++) {
            final row = csvData[i];
            final sale = Sale(
              productName: row[0].toString(),
              category: row[1].toString(),
              quantity: int.tryParse(row[2].toString()) ?? 0,
              sellingPrice: double.tryParse(row[3].toString()) ?? 0.0,
              totalAmount: double.tryParse(row[4].toString()) ?? 0.0,
              timestamp: DateTime.tryParse(row[5].toString()) ?? DateTime.now(),
            );
            await salesBox.add(sale);
          }
        } else if (headers.contains('Store Name')) {
          // Import Settings
          final settingsBox = Hive.box<AppSettings>('settings');
          final row = csvData[1];
          final settings = AppSettings(
            storeName: row[0].toString(),
            ownerName: row[1].toString(),
            pin: row[2].toString(),
            minimumProfitMargin: double.tryParse(row[3].toString()) ?? 0.0,
            autoDiscountEnabled: row[4].toString().toLowerCase() == 'true',
            syncEnabled: row[5].toString().toLowerCase() == 'true',
            backupEnabled: row[6].toString().toLowerCase() == 'true',
          );
          await settingsBox.put(0, settings);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all products, sales, and settings. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Hive.box<Product>('products').clear();
      await Hive.box<Sale>('sales').clear();
      await Hive.box<AppSettings>('settings').clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export All Data'),
              subtitle: const Text('Export products, sales, alerts, and settings to CSV'),
              onTap: _exportAllData,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Import from CSV'),
              subtitle: const Text('Import data from CSV files'),
              onTap: _importFromCSV,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All Data'),
              subtitle: const Text('Permanently delete all stored data'),
              onTap: _clearAllData,
            ),
          ),
        ],
      ),
    );
  }
}
