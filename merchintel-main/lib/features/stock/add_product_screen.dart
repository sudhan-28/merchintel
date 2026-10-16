import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../data/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _costCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  int quantity = 1;
  DateTime? expiryDate;
  String category = 'General';

  double get profitMargin {
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (cost <= 0) return 0;
    return ((price - cost) / cost) * 100;
  }

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final product = widget.productToEdit!;
      _nameCtrl.text = product.name;
      _costCtrl.text = product.costPrice.toString();
      _priceCtrl.text = product.sellingPrice.toString();
      quantity = product.quantity;
      expiryDate = product.expiryDate;
      category = product.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProfitGood = profitMargin >= 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textField(
                    controller: _nameCtrl,
                    label: 'Product Name',
                  ),

                  const SizedBox(height: 16),

                  _categoryDropdown(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _costCtrl,
                          label: 'Cost Price',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(
                          controller: _priceCtrl,
                          label: 'Selling Price',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Profit Margin: ${profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isProfitGood
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _quantitySelector(),

                  const SizedBox(height: 20),

                  _expiryPicker(context),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _saveProduct,
                      child: Text(widget.productToEdit != null ? 'Update Product' : 'Save Product'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Widgets ----------------

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      value: category,
      items: const [
        DropdownMenuItem(value: 'General', child: Text('General')),
        DropdownMenuItem(value: 'Food', child: Text('Food')),
        DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
        DropdownMenuItem(value: 'Household', child: Text('Household')),
      ],
      onChanged: (v) => setState(() => category = v!),
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _quantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: quantity > 1
              ? () => setState(() => quantity--)
              : null,
        ),
        Text(
          quantity.toString(),
          style: const TextStyle(fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => setState(() => quantity++),
        ),
      ],
    );
  }

  Widget _expiryPicker(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Expiry Date'),
      subtitle: Text(
        expiryDate == null
            ? 'Select date'
            : '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
        );
        if (picked != null) {
          setState(() => expiryDate = picked);
        }
      },
    );
  }

  // ---------------- SAVE TO HIVE ----------------

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final box = Hive.box<Product>('products');

    // Check for duplicate product names
    final existingProducts = box.values.where((p) => p.name.toLowerCase() == _nameCtrl.text.toLowerCase());
    if (widget.productToEdit != null) {
      // Exclude current product when editing
      if (existingProducts.any((p) => p != widget.productToEdit)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A product with this name already exists')),
        );
        return;
      }
    } else {
      if (existingProducts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A product with this name already exists')),
        );
        return;
      }
    }

    // Ensure quantity is not negative
    if (quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity cannot be negative')),
      );
      return;
    }

    final product = Product(
      name: _nameCtrl.text,
      category: category,
      costPrice: double.parse(_costCtrl.text),
      sellingPrice: double.parse(_priceCtrl.text),
      quantity: quantity,
      expiryDate: expiryDate,
    );

    if (widget.productToEdit != null) {
      // Update existing product
      final index = box.values.toList().indexOf(widget.productToEdit!);
      if (index != -1) {
        await box.putAt(index, product);
      }
    } else {
      // Add new product
      await box.add(product);
    }

    Navigator.pop(context);
  }
}
