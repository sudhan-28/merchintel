import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String category;

  @HiveField(2)
  double costPrice;

  @HiveField(3)
  double sellingPrice;

  @HiveField(4)
  int quantity;

  @HiveField(5)
  DateTime? expiryDate;

  Product({
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    this.expiryDate,
  });
}
