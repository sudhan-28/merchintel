import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  double minimumProfitMargin = 10.0;

  @HiveField(1)
  bool autoDiscountEnabled = false;

  @HiveField(2)
  bool syncEnabled = false;

  @HiveField(3)
  bool backupEnabled = true;

  @HiveField(4)
  String? storeName;

  @HiveField(5)
  String? ownerName;

  @HiveField(6)
  String? pin;

  @HiveField(7)
  DateTime? lastBackupDate;

  @HiveField(8)
  bool isDemoMode = false;

  AppSettings({
    this.minimumProfitMargin = 10.0,
    this.autoDiscountEnabled = false,
    this.syncEnabled = false,
    this.backupEnabled = true,
    this.storeName,
    this.ownerName,
    this.pin,
    this.lastBackupDate,
    this.isDemoMode = false,
  });
}
