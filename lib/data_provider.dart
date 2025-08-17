import 'package:flutter/material.dart';
import 'models.dart';
import 'hive_service.dart';

class DataProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Client> _clients = [];
  List<Category> _categories = [];
  List<Invoice> _invoices = [];

  List<Product> get products => _products;
  List<Client> get clients => _clients;
  List<Category> get categories => _categories;
  List<Invoice> get invoices => _invoices;

  DataProvider() {
    loadInitialData();
  }

  void loadInitialData() {
    _products = HiveService.productsBox.values.toList();
    _clients = HiveService.clientsBox.values.toList();
    _categories = HiveService.categoriesBox.values.toList();
    _invoices = HiveService.invoicesBox.values.toList();

    // Initialize with sample data if empty
    if (_categories.isEmpty) {
      _categories = [
        Category(id: '1', name: 'كرتونة'),
        Category(id: '2', name: 'علبة'),
        Category(id: '3', name: 'يكن'),
        Category(id: 'piece', name: 'قطعة'), // Added 'piece' category
      ];
      // Save categories to Hive directly
      for (var category in _categories) {
        HiveService.categoriesBox.put(category.id, category);
      }
    }
    if (_products.isEmpty) {
      _products = [
        Product(id: '1', name: 'لابتوب HP', barcode: '1234567890', price: 15000.0, purchasePrice: 12000.0, quantity: 10, categoryId: '1'),
        Product(id: '2', name: 'ماوس لاسلكي', barcode: '0987654321', price: 250.0, purchasePrice: 200.0, quantity: 25, categoryId: '2'),
      ];
      // Save products to Hive directly
      for (var product in _products) {
        HiveService.productsBox.put(product.id, product);
      }
    }
    if (_clients.isEmpty) {
      _clients = [
        Client(id: '1', name: 'أحمد محمد', phone: '01234567890', email: 'ahmed@email.com', type: 'buyer', balance: 500.0),
        Client(id: '2', name: 'فاطمة علي', phone: '01987654321', email: 'fatima@email.com', type: 'supplier', balance: -200.0),
      ];
      // Save clients to Hive directly
      for (var client in _clients) {
        HiveService.clientsBox.put(client.id, client);
      }
    }
    notifyListeners();
  }

  void addProduct(Product product) {
    if (!_categories.any((c) => c.id == product.categoryId)) {
      throw Exception('التصنيف غير موجود: ${product.categoryId}');
    }
    _products.add(product);
    HiveService.productsBox.put(product.id, product);
    notifyListeners();
  }

  void updateProduct(Product product) {
    if (!_categories.any((c) => c.id == product.categoryId)) {
      throw Exception('التصنيف غير موجود: ${product.categoryId}');
    }
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      HiveService.productsBox.put(product.id, product);
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    HiveService.productsBox.delete(id);
    notifyListeners();
  }

  void addClient(Client client) {
    _clients.add(client);
    HiveService.clientsBox.put(client.id, client);
    notifyListeners();
  }

  void updateClient(Client client) {
    final index = _clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _clients[index] = client;
      HiveService.clientsBox.put(client.id, client);
      notifyListeners();
    }
  }

  void deleteClient(String id) {
    _clients.removeWhere((c) => c.id == id);
    HiveService.clientsBox.delete(id);
    notifyListeners();
  }

  void addCategory(Category category) {
    _categories.add(category);
    HiveService.categoriesBox.put(category.id, category);
    notifyListeners();
  }

  void updateCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      HiveService.categoriesBox.put(category.id, category);
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    if (_products.any((p) => p.categoryId == id)) {
      throw Exception('لا يمكن حذف التصنيف لأنه مرتبط بمنتجات.');
    }
    _categories.removeWhere((c) => c.id == id);
    HiveService.categoriesBox.delete(id);
    notifyListeners();
  }

  void addInvoice(Invoice invoice) {
    _invoices.add(invoice);
    HiveService.invoicesBox.put(invoice.id, invoice);
    notifyListeners();
  }

  void updateInvoice(Invoice invoice) {
    final index = _invoices.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      _invoices[index] = invoice;
      HiveService.invoicesBox.put(invoice.id, invoice);
      notifyListeners();
    }
  }
}