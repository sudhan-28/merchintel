import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 2)
class Sale extends HiveObject {
  @HiveField(0)
  String productName;

  @HiveField(1)
  String category;

  @HiveField(2)
  double sellingPrice;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  double totalAmount;

  @HiveField(5)
  DateTime timestamp;

  Sale({
    required this.productName,
    required this.category,
    required this.sellingPrice,
    required this.quantity,
    required this.totalAmount,
    required this.timestamp,
  });
}
