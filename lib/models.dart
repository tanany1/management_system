import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String barcode;
  @HiveField(3)
  final double price;
  @HiveField(4)
  final double purchasePrice;
  @HiveField(5)
  final int quantity;
  @HiveField(6)
  final String categoryId;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.purchasePrice,
    required this.quantity,
    required this.categoryId,
  });
}

@HiveType(typeId: 1)
class Client {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String phone;
  @HiveField(3)
  final String email;
  @HiveField(4)
  final String type;
  @HiveField(5)
  final double balance;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.type,
    this.balance = 0.0,
  });
}

@HiveType(typeId: 2)
class Category {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;

  Category({required this.id, required this.name});
}

@HiveType(typeId: 3)
class InvoiceItem {
  @HiveField(0)
  String productId;
  @HiveField(1)
  String name;
  @HiveField(2)
  String categoryId;
  @HiveField(3)
  int quantity;
  @HiveField(4)
  double price;
  @HiveField(5)
  double purchasePrice;

  InvoiceItem({
    required this.productId,
    required this.name,
    required this.categoryId,
    required this.quantity,
    required this.price,
    required this.purchasePrice,
  });
}

@HiveType(typeId: 4)
class Invoice {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String invoiceNumber;
  @HiveField(2)
  final String clientId;
  @HiveField(3)
  final bool isDeferred;
  @HiveField(4)
  final List<InvoiceItem> items;
  @HiveField(5)
  final String type; // 'outgoing' or 'incoming'
  @HiveField(6)
  final DateTime date;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.isDeferred,
    required this.items,
    required this.type,
    required this.date,
  });
}