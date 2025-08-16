import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'dart:io';
import 'models.dart';

class HiveService {
  static Future<void> initHive() async {
    String hivePath;
    try {
      final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
      hivePath = appDocumentDir.path;
    } catch (e) {
      // Fallback for platforms where getApplicationDocumentsDirectory is not supported
      hivePath = p.join(Directory.current.path, 'hive_data');
      await Directory(hivePath).create(recursive: true); // Create directory if it doesn't exist
    }

    await Hive.initFlutter(hivePath);
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    await Hive.openBox<Product>('products');
    await Hive.openBox<Client>('clients');
    await Hive.openBox<Category>('categories');
    await Hive.openBox<Invoice>('invoices');
  }

  static Box<Product> get productsBox => Hive.box<Product>('products');
  static Box<Client> get clientsBox => Hive.box<Client>('clients');
  static Box<Category> get categoriesBox => Hive.box<Category>('categories');
  static Box<Invoice> get invoicesBox => Hive.box<Invoice>('invoices');
}