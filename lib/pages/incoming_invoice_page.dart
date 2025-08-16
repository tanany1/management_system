import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models.dart';

class IncomingInvoicePage extends StatefulWidget {
  const IncomingInvoicePage({super.key});

  @override
  State<IncomingInvoicePage> createState() => _IncomingInvoicePageState();
}

class _IncomingInvoicePageState extends State<IncomingInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController(text: 'PUR-${DateTime.now().millisecondsSinceEpoch}');
  String? _selectedSupplierId;
  bool _isDeferred = false;
  List<InvoiceItem> items = [
    InvoiceItem(productId: '', name: '', categoryId: '', quantity: 1, price: 0.0, purchasePrice: 0.0),
  ];

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
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
    if (_formKey.currentState!.validate() && _selectedSupplierId != null) {
      final provider = context.read<DataProvider>();
      // Update supplier balance
      if (_isDeferred) {
        final supplier = provider.clients.firstWhere((s) => s.id == _selectedSupplierId);
        provider.updateClient(Client(
          id: supplier.id,
          name: supplier.name,
          phone: supplier.phone,
          email: supplier.email,
          type: supplier.type,
          balance: supplier.balance + totalAmount,
        ));
      }
      // Update product quantities
      for (var item in items) {
        final productIndex = provider.products.indexWhere((p) => p.id == item.productId);
        if (productIndex != -1) {
          final product = provider.products[productIndex];
          provider.updateProduct(Product(
            id: product.id,
            name: product.name,
            barcode: product.barcode,
            price: product.price,
            purchasePrice: item.purchasePrice,
            quantity: product.quantity + item.quantity,
            categoryId: product.categoryId,
          ));
        } else {
          // Add new product if not exists
          provider.addProduct(Product(
            id: item.productId,
            name: item.name,
            barcode: DateTime.now().millisecondsSinceEpoch.toString(),
            price: item.price,
            purchasePrice: item.purchasePrice,
            quantity: item.quantity,
            categoryId: item.categoryId,
          ));
        }
      }
      // Save invoice
      provider.addInvoice(Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invoiceNumber: _invoiceNumberController.text,
        clientId: _selectedSupplierId!,
        isDeferred: _isDeferred,
        items: items,
        type: 'incoming',
        date: DateTime.now(),
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ فاتورة الوارد بنجاح')),
      );
      // Reset form
      _formKey.currentState?.reset();
      _invoiceNumberController.text = 'PUR-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        items = [InvoiceItem(productId: '', name: '', categoryId: '', quantity: 1, price: 0.0, purchasePrice: 0.0)];
        _selectedSupplierId = null;
        _isDeferred = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final products = provider.products;
    final suppliers = provider.clients.where((client) => client.type == 'supplier').toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _formKey.currentState?.reset();
                  _invoiceNumberController.text = 'PUR-${DateTime.now().millisecondsSinceEpoch}';
                  setState(() {
                    items = [InvoiceItem(productId: '', name: '', categoryId: '', quantity: 1, price: 0.0, purchasePrice: 0.0)];
                    _selectedSupplierId = null;
                    _isDeferred = false;
                  });
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إنشاء فاتورة وارد جديدة', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const Text('الوارد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                        'ملخص فاتورة الوارد',
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
                            value: _selectedSupplierId,
                            decoration: const InputDecoration(labelText: 'المورد', border: OutlineInputBorder()),
                            items: suppliers
                                .map((supplier) => DropdownMenuItem(
                              value: supplier.id,
                              child: Text(supplier.name, textAlign: TextAlign.right),
                            ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedSupplierId = value),
                            validator: (value) => value == null ? 'يرجى اختيار مورد' : null,
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
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    initialValue: items[index].purchasePrice.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'سعر الشراء',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) => double.tryParse(value ?? '') == null || double.parse(value!) <= 0
                                        ? 'يرجى إدخال سعر شراء صحيح'
                                        : null,
                                    onChanged: (value) {
                                      setState(() {
                                        items[index].purchasePrice = double.tryParse(value) ?? 0.0;
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
                                    items: products
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