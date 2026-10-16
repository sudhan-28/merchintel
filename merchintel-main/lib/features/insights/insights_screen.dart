import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/product.dart';
import '../../data/settings.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<Product> _discountSuggestions = [];
  List<Product> _shelfMoveSuggestions = [];
  List<Map<String, dynamic>> _inventoryInsights = [];
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _calculateInsights();
  }

  Future<void> _calculateInsights() async {
    if (_isCalculating) return;
    _isCalculating = true;

    final products = Hive.box<Product>('products').values.toList();
    final settings = Hive.box<AppSettings>('settings').get('app_settings') ?? AppSettings();

    if (products.isEmpty) {
      _isCalculating = false;
      return;
    }

    // Pre-calculate common values to avoid repeated computations
    final now = DateTime.now();
    final totalProducts = products.length;
    final avgSellingPrice = products.fold<double>(0, (sum, p) => sum + p.sellingPrice) / totalProducts;
    final avgQuantity = products.fold<double>(0, (sum, p) => sum + p.quantity) / totalProducts;

    // Calculate discount suggestions with optimized logic
    _discountSuggestions = [];
    for (final product in products) {
      final profitMargin = ((product.sellingPrice - product.costPrice) / product.costPrice) * 100;
      final isLowMargin = profitMargin < settings.minimumProfitMargin;
      final isLowStock = product.quantity <= 5;
      final isNearExpiry = product.expiryDate != null &&
          product.expiryDate!.difference(now).inDays <= 30;

      if (isLowMargin || isLowStock || isNearExpiry) {
        _discountSuggestions.add(product);
      }
    }

    // Calculate shelf move suggestions
    _shelfMoveSuggestions = [];
    for (final product in products) {
      final isHighValue = product.sellingPrice > avgSellingPrice * 1.2;
      final isHighStock = product.quantity > avgQuantity * 1.5;
      final isLowStockHighValue = product.quantity <= 3 && product.sellingPrice > avgSellingPrice;

      if (isHighValue || isHighStock || isLowStockHighValue) {
        _shelfMoveSuggestions.add(product);
      }
    }

    // Calculate inventory insights with single pass
    double totalValue = 0;
    double totalCost = 0;
    int expiringSoon = 0;
    int lowStock = 0;
    int deadStock = 0;

    for (final product in products) {
      totalValue += product.sellingPrice * product.quantity;
      totalCost += product.costPrice * product.quantity;

      if (product.expiryDate != null && product.expiryDate!.difference(now).inDays <= 30) {
        expiringSoon++;
      }

      if (product.quantity <= 5) {
        lowStock++;
      }

      if (product.quantity <= 2 && (product.expiryDate == null || product.expiryDate!.isBefore(now))) {
        deadStock++;
      }
    }

    final avgMargin = totalCost > 0 ? ((totalValue - totalCost) / totalCost) * 100 : 0.0;

    _inventoryInsights = [
      {
        'title': 'Average Profit Margin',
        'value': '${avgMargin.toStringAsFixed(1)}%',
        'icon': Icons.trending_up,
        'color': avgMargin >= settings.minimumProfitMargin ? Colors.green : Colors.orange,
      },
      {
        'title': 'Products Expiring Soon',
        'value': '$expiringSoon',
        'icon': Icons.schedule,
        'color': expiringSoon > 0 ? Colors.red : Colors.green,
      },
      {
        'title': 'Low Stock Items',
        'value': '$lowStock',
        'icon': Icons.inventory_2,
        'color': lowStock > 0 ? Colors.orange : Colors.green,
      },
      {
        'title': 'Dead Stock Items',
        'value': '$deadStock',
        'icon': Icons.cancel,
        'color': deadStock > 0 ? Colors.red : Colors.green,
      },
    ];

    _isCalculating = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateInsights,
            tooltip: 'Refresh Insights',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          // Recalculate when data changes
          WidgetsBinding.instance.addPostFrameCallback((_) => _calculateInsights());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Inventory Overview Cards
              const Text(
                'Inventory Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: _inventoryInsights.length,
                itemBuilder: (context, index) {
                  final insight = _inventoryInsights[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            insight['icon'] as IconData,
                            size: 32,
                            color: insight['color'] as Color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            insight['value'] as String,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: insight['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight['title'] as String,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Discount Suggestions
              if (_discountSuggestions.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.local_offer, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Discount Suggestions (${_discountSuggestions.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._discountSuggestions.map((product) {
                  final profitMargin = ((product.sellingPrice - product.costPrice) / product.costPrice) * 100;
                  final settings = Hive.box<AppSettings>('settings').get('app_settings') ?? AppSettings();
                  final isLowMargin = profitMargin < settings.minimumProfitMargin;

                  return Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.local_offer, color: Colors.green),
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current margin: ${profitMargin.toStringAsFixed(1)}%'),
                          if (isLowMargin)
                            Text('Suggested: Increase price or reduce costs',
                                style: const TextStyle(color: Colors.red)),
                          if (product.quantity <= 5)
                            Text('Low stock: ${product.quantity} remaining',
                                style: const TextStyle(color: Colors.orange)),
                          if (product.expiryDate != null &&
                              product.expiryDate!.difference(DateTime.now()).inDays <= 30)
                            Text('Expires: ${product.expiryDate!.day}/${product.expiryDate!.month}',
                                style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                      trailing: Text('₹${product.sellingPrice.toStringAsFixed(0)}'),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Shelf Move Suggestions
              if (_shelfMoveSuggestions.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.move_up, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Shelf Optimization (${_shelfMoveSuggestions.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._shelfMoveSuggestions.map((product) {
                  final products = Hive.box<Product>('products').values.toList();
                  final avgPrice = products.map((p) => p.sellingPrice).reduce((a, b) => a + b) / products.length;
                  final isHighValue = product.sellingPrice > avgPrice * 1.2;

                  return Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: Icon(
                        isHighValue ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.blue,
                      ),
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: ₹${product.sellingPrice.toStringAsFixed(0)}'),
                          Text('Stock: ${product.quantity} units'),
                          if (isHighValue)
                            const Text('Suggestion: Move to premium shelf position',
                                style: TextStyle(color: Colors.green)),
                          if (product.quantity <= 3 && product.sellingPrice > avgPrice)
                            const Text('High-value, low stock: Consider restocking',
                                style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // Empty state
              if (_discountSuggestions.isEmpty && _shelfMoveSuggestions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'Your inventory is well-optimized!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No immediate actions needed.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
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
