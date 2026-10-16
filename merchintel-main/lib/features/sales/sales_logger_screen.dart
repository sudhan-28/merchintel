import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/product.dart';
import '../../data/sale.dart';

class SalesLoggerScreen extends StatefulWidget {
  const SalesLoggerScreen({super.key});

  @override
  State<SalesLoggerScreen> createState() => _SalesLoggerScreenState();
}

class _SalesLoggerScreenState extends State<SalesLoggerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Product? _selectedProduct;
  int _quantity = 1;
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadProducts() {
    final box = Hive.box<Product>('products');
    _filteredProducts = box.values.toList();
    setState(() {});
  }

  void _filterProducts() {
    final query = _searchCtrl.text.toLowerCase();
    final box = Hive.box<Product>('products');
    _filteredProducts = box.values
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();
    setState(() {});
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _quantity = 1;
      _searchCtrl.text = product.name;
    });
  }

  Future<void> _logSale() async {
    if (_selectedProduct == null) return;

    if (_quantity > _selectedProduct!.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient stock!')),
      );
      return;
    }

    try {
      final productBox = Hive.box<Product>('products');
      final saleBox = Hive.box<Sale>('sales');
      final index = productBox.values.toList().indexOf(_selectedProduct!);
      if (index != -1) {
        final updatedProduct = Product(
          name: _selectedProduct!.name,
          category: _selectedProduct!.category,
          costPrice: _selectedProduct!.costPrice,
          sellingPrice: _selectedProduct!.sellingPrice,
          quantity: _selectedProduct!.quantity - _quantity,
          expiryDate: _selectedProduct!.expiryDate,
        );
        await productBox.putAt(index, updatedProduct);

        // Save sale record
        final sale = Sale(
          productName: _selectedProduct!.name,
          category: _selectedProduct!.category,
          sellingPrice: _selectedProduct!.sellingPrice,
          quantity: _quantity,
          totalAmount: _selectedProduct!.sellingPrice * _quantity,
          timestamp: DateTime.now(),
        );
        await saleBox.add(sale);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale logged: $_quantity x ${_selectedProduct!.name}')),
        );

        setState(() {
          _selectedProduct = null;
          _searchCtrl.clear();
          _quantity = 1;
          _loadProducts();
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging sale: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search Product',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty && _filteredProducts.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('Stock: ${product.quantity}'),
                      onTap: () => _selectProduct(product),
                    );
                  },
                ),
              ),

            if (_selectedProduct != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedProduct!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Price: ₹${_selectedProduct!.sellingPrice}'),
                      Text('Available: ${_selectedProduct!.quantity}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Quantity'),
                  const Spacer(),
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_quantity'),
                  IconButton(
                    onPressed: _quantity < _selectedProduct!.quantity
                        ? () => setState(() => _quantity++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Total: ₹${(_selectedProduct!.sellingPrice * _quantity).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _selectedProduct != null ? _logSale : null,
                child: const Text('Log Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
