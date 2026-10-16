import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/product.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Product> _lowStockProducts = [];
  List<Product> _highPriorityExpiry = [];
  List<Product> _mediumPriorityExpiry = [];
  List<Product> _lowPriorityExpiry = [];
  List<Product> _deadStock = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    final box = Hive.box<Product>('products');
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    final sixtyDaysFromNow = now.add(const Duration(days: 60));

    _lowStockProducts = box.values.where((product) => product.quantity <= 5).toList();

    // Expiring within 7 days - High priority
    _highPriorityExpiry = box.values
        .where((product) =>
            product.expiryDate != null &&
            product.expiryDate!.isAfter(now) &&
            product.expiryDate!.isBefore(sevenDaysFromNow))
        .toList();

    // Expiring within 30 days - Medium priority
    _mediumPriorityExpiry = box.values
        .where((product) =>
            product.expiryDate != null &&
            product.expiryDate!.isAfter(sevenDaysFromNow) &&
            product.expiryDate!.isBefore(thirtyDaysFromNow))
        .toList();

    // Expiring within 60 days - Low priority
    _lowPriorityExpiry = box.values
        .where((product) =>
            product.expiryDate != null &&
            product.expiryDate!.isAfter(thirtyDaysFromNow) &&
            product.expiryDate!.isBefore(sixtyDaysFromNow))
        .toList();

    // Dead stock detection - products with very low stock and old expiry
    _deadStock = box.values
        .where((product) =>
            product.quantity <= 2 &&
            (product.expiryDate == null || product.expiryDate!.isBefore(now)))
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          // Recalculate alerts when data changes
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadAlerts());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_deadStock.isNotEmpty)
                Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Dead Stock Alert',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._deadStock.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${product.name}: ${product.quantity} remaining',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

              if (_highPriorityExpiry.isNotEmpty)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'High Priority Expiry (7 days)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._highPriorityExpiry.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${product.name}: Expires ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

              if (_mediumPriorityExpiry.isNotEmpty)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Medium Priority Expiry (30 days)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._mediumPriorityExpiry.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${product.name}: Expires ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

              if (_lowPriorityExpiry.isNotEmpty)
                Card(
                  color: Colors.yellow.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: Colors.yellow),
                            SizedBox(width: 8),
                            Text(
                              'Low Priority Expiry (60 days)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._lowPriorityExpiry.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${product.name}: Expires ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

              if (_lowStockProducts.isNotEmpty)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.inventory, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Low Stock Alert',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._lowStockProducts.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${product.name}: ${product.quantity} remaining',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

              if (_lowStockProducts.isEmpty &&
                  _highPriorityExpiry.isEmpty &&
                  _mediumPriorityExpiry.isEmpty &&
                  _lowPriorityExpiry.isEmpty &&
                  _deadStock.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No alerts at this time.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
