import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/product.dart';
import 'data/sale.dart';
import 'data/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(SaleAdapter());
  await Hive.openBox<Product>('products');
  await Hive.openBox<AppSettings>('settings');
  await Hive.openBox<Sale>('sales');

  runApp(const ShelfIntelligenceApp());
}
