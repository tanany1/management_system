import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController(text: 'INV-${DateTime.now().millisecondsSinceEpoch}');
  String? _selectedClientId;
  bool _isDeferred = false;
  List<InvoiceItem> items = [
    InvoiceItem(productId: '', name: '', categoryId: '', quantity: 1, price: 0.0, purchasePrice: 0.0),
  ];

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }

  void addNewItem() {
    setState(() {
      items.add(InvoiceItem(productId: '', name: '', categoryId: '', quantity: 1, price: 0.0, purchasePrice: 0.0));
    });
  }

  void removeItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
      });
    }
  }

  void _saveInvoice(BuildContext context) {
    if (_formKey.currentState!.validate() && _selectedClientId != null) {
      final provider = context.read<DataProvider>();
      // Update client balance
      if (_isDeferred) {
        final client = provider.clients.firstWhere((c) => c.id == _selectedClientId);
        provider.updateClient(Client(
          id: client.id,
          name: client.name,
          phone: client.phone,
          email: client.email,
          type: client.type,
          balance: client.balance - totalAmount,
        ));
      }
      // Update product quantities
      for (var item in items) {
        final productIndex = provider.products.indexWhere((p) => p.id == item.productId);
        if (productIndex != -1) {
          final product = provider.products[productIndex];
          if (product.quantity >= item.quantity) {
            provider.updateProduct(Product(
              id: product.id,
              name: product.name,
              barcode: product.barcode,
              price: product.price,
              purchasePrice: product.purchasePrice,
              quantity: product.quantity - item.quantity,
              categoryId: product.categoryId,
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('الكمية غير كافية للمنتج: ${product.name}')),
            );
            return;
          }
        }
      }
      // Save invoice
      final invoice = Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invoiceNumber: _invoiceNumberController.text,
        clientId: _selectedClientId!,
        isDeferred: _isDeferred,
        items: items,
        type: 'outgoing',
        date: DateTime.now(),
      );
      provider.addInvoice(invoice);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ فاتورة الصادر بنجاح')),
      );
      // Reset form
      _formKey.currentState?.reset();
      _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        items = [InvoiceItem(productId: '', name: '', categoryId: '', quantity: 1, price: 0.0, purchasePrice: 0.0)];
        _selectedClientId = null;
        _isDeferred = false;
      });
    }
  }

  void _showInvoiceDialog(BuildContext context) {
    final provider = context.read<DataProvider>();
    final client = provider.clients.firstWhere((c) => c.id == _selectedClientId, orElse: () => Client(id: '', name: 'غير محدد', phone: '', email: '', type: 'buyer', balance: 0.0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل فاتورة الصادر', textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('رقم الفاتورة: ${_invoiceNumberController.text}', textAlign: TextAlign.right),
              Text('العميل: ${client.name}', textAlign: TextAlign.right),
              Text('التاريخ: ${DateTime.now().toString().substring(0, 10)}', textAlign: TextAlign.right),
              const SizedBox(height: 20),
              const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${index + 1}. ${item.name} - الكمية: ${item.quantity} - السعر: ${item.price.toStringAsFixed(2)} ج.م - الإجمالي: ${(item.quantity * item.price).toStringAsFixed(2)} ج.م',
                    textAlign: TextAlign.right,
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text('المبلغ الإجمالي: ${totalAmount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final products = provider.products;
    final categories = provider.categories;
    final clients = provider.clients.where((client) => client.type == 'buyer').toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch}';
                      setState(() {
                        items = [InvoiceItem(productId: '', name: '', categoryId: '', quantity: 1, price: 0.0, purchasePrice: 0.0)];
                        _selectedClientId = null;
                        _isDeferred = false;
                      });
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إنشاء فاتورة صادر جديدة', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _selectedClientId != null && items.every((item) => item.productId.isNotEmpty)
                        ? () => _showInvoiceDialog(context)
                        : null,
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    label: const Text('عرض الفاتورة', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
              const Text('الصادر', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'ملخص فاتورة الصادر',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _invoiceNumberController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'رقم الفاتورة',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty ? 'يرجى إدخال رقم الفاتورة' : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedClientId,
                            decoration: const InputDecoration(labelText: 'العميل (مشتري)', border: OutlineInputBorder()),
                            items: clients
                                .map((client) => DropdownMenuItem(
                              value: client.id,
                              child: Text(client.name, textAlign: TextAlign.right),
                            ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedClientId = value),
                            validator: (value) => value == null ? 'يرجى اختيار عميل' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _isDeferred,
                          onChanged: (value) => setState(() => _isDeferred = value!),
                        ),
                        const Text('دفع مؤجل', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.lightBlue, borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'إضافة منتجات',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final filteredProducts = items[index].categoryId.isEmpty
                              ? products
                              : products.where((product) => product.categoryId == items[index].categoryId).toList();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => removeItem(index),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    initialValue: items[index].quantity.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'الكمية',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0
                                        ? 'يرجى إدخال كمية صحيحة'
                                        : null,
                                    onChanged: (value) {
                                      setState(() {
                                        items[index].quantity = int.tryParse(value) ?? 1;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: items[index].categoryId.isEmpty ? null : items[index].categoryId,
                                    decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('جميع التصنيفات', textAlign: TextAlign.right)),
                                      ...categories.map((category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.name, textAlign: TextAlign.right),
                                      )),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        items[index].categoryId = value ?? '';
                                        items[index].productId = ''; // Reset product selection when category changes
                                        items[index].name = '';
                                        items[index].price = 0.0;
                                        items[index].purchasePrice = 0.0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 4,
                                  child: DropdownButtonFormField<String>(
                                    value: items[index].productId.isEmpty ? null : items[index].productId,
                                    decoration: const InputDecoration(labelText: 'المنتج', border: OutlineInputBorder()),
                                    items: filteredProducts
                                        .map((product) => DropdownMenuItem(
                                      value: product.id,
                                      child: Text('${product.name} (${product.categoryId})', textAlign: TextAlign.right),
                                    ))
                                        .toList(),
                                    validator: (value) => value == null ? 'يرجى اختيار منتج' : null,
                                    onChanged: (value) {
                                      setState(() {
                                        final selectedProduct = products.firstWhere((p) => p.id == value);
                                        items[index].productId = value!;
                                        items[index].name = selectedProduct.name;
                                        items[index].categoryId = selectedProduct.categoryId;
                                        items[index].price = selectedProduct.price;
                                        items[index].purchasePrice = selectedProduct.purchasePrice;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: addNewItem,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('إضافة منتج', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${totalAmount.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const Text('المبلغ الإجمالي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _saveInvoice(context),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    super.dispose();
  }
}