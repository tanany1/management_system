import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models.dart';
import 'invoice_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedReportType = 'invoices';
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final invoices = provider.invoices;
    final products = provider.products;
    final clients = provider.clients;

    List<Map<String, dynamic>> reportData = [];
    double totalSales = 0.0;
    double totalPurchases = 0.0;
    double totalProfit = 0.0;

    if (selectedReportType == 'invoices') {
      final filteredInvoices = invoices.where((invoice) => invoice.type == 'outgoing').toList();
      for (var invoice in filteredInvoices) {
        if ((startDate == null || invoice.date.isAfter(startDate!)) &&
            (endDate == null || invoice.date.isBefore(endDate!))) {
          double invoiceTotal = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
          double invoiceCost = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
          totalSales += invoiceTotal;
          totalProfit += invoiceTotal - invoiceCost;
          reportData.add({
            'invoiceNumber': invoice.invoiceNumber,
            'client': clients.firstWhere((c) => c.id == invoice.clientId).name,
            'date': invoice.date.toString().substring(0, 10),
            'total': invoiceTotal,
            'profit': invoiceTotal - invoiceCost,
            'invoice': invoice,
          });
        }
      }
    } else if (selectedReportType == 'sales') {
      final filteredInvoices = invoices.where((invoice) => invoice.type == 'outgoing').toList();
      for (var invoice in filteredInvoices) {
        if ((startDate == null || invoice.date.isAfter(startDate!)) &&
            (endDate == null || invoice.date.isBefore(endDate!))) {
          double invoiceTotal = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
          double invoiceCost = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
          totalSales += invoiceTotal;
          totalProfit += invoiceTotal - invoiceCost;
          reportData.add({
            'invoiceNumber': invoice.invoiceNumber,
            'client': clients.firstWhere((c) => c.id == invoice.clientId).name,
            'date': invoice.date.toString().substring(0, 10),
            'total': invoiceTotal,
            'profit': invoiceTotal - invoiceCost,
          });
        }
      }
    } else if (selectedReportType == 'purchases') {
      final filteredInvoices = invoices.where((invoice) => invoice.type == 'incoming').toList();
      for (var invoice in filteredInvoices) {
        if ((startDate == null || invoice.date.isAfter(startDate!)) &&
            (endDate == null || invoice.date.isBefore(endDate!))) {
          double invoiceTotal = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
          totalPurchases += invoiceTotal;
          reportData.add({
            'invoiceNumber': invoice.invoiceNumber,
            'supplier': clients.firstWhere((c) => c.id == invoice.clientId).name,
            'date': invoice.date.toString().substring(0, 10),
            'total': invoiceTotal,
          });
        }
      }
    } else if (selectedReportType == 'inventory') {
      reportData = products
          .map((product) => {
        'name': product.name,
        'quantity': product.quantity,
        'price': product.price,
        'purchasePrice': product.purchasePrice,
        'category': provider.categories.firstWhere(
              (c) => c.id == product.categoryId,
          orElse: () => Category(id: 'unknown', name: 'غير مصنف'),
        ).name,
      })
          .toList();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('التقارير', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                      child: const Text('تحديد الفترة'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('الفواتير'),
                  selected: selectedReportType == 'invoices',
                  onSelected: (selected) => setState(() => selectedReportType = 'invoices'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('المخزن'),
                  selected: selectedReportType == 'inventory',
                  onSelected: (selected) => setState(() => selectedReportType = 'inventory'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('المبيعات'),
                  selected: selectedReportType == 'sales',
                  onSelected: (selected) => setState(() => selectedReportType = 'sales'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('المشتريات'),
                  selected: selectedReportType == 'purchases',
                  onSelected: (selected) => setState(() => selectedReportType = 'purchases'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedReportType != 'inventory')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    selectedReportType == 'sales' || selectedReportType == 'invoices'
                        ? 'إجمالي المبيعات: ${totalSales.toStringAsFixed(2)} ج.م | إجمالي الربح: ${totalProfit.toStringAsFixed(2)} ج.م'
                        : 'إجمالي المشتريات: ${totalPurchases.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: selectedReportType == 'inventory'
                            ? const [
                          Expanded(flex: 3, child: Text('اسم المنتج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('سعر البيع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('سعر الشراء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('الكمية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('التصنيف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ]
                            : selectedReportType == 'invoices' || selectedReportType == 'sales'
                            ? const [
                          Expanded(flex: 2, child: Text('رقم الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 3, child: Text('العميل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('الإجمالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('الربح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('الإجراءات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ]
                            : const [
                          Expanded(flex: 2, child: Text('رقم الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 3, child: Text('المورد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('الإجمالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: reportData.isEmpty
                          ? const Center(child: Text('لا توجد بيانات للتقرير', style: TextStyle(fontSize: 16, color: Colors.grey)))
                          : ListView.builder(
                        itemCount: reportData.length,
                        itemBuilder: (context, index) {
                          final data = reportData[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: selectedReportType == 'inventory'
                                  ? [
                                Expanded(flex: 3, child: Text(data['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('${data['price'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 2, child: Text('${data['purchasePrice'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 2, child: Text(data['quantity'].toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: data['quantity'] < 5 ? Colors.red : Colors.black))),
                                Expanded(flex: 2, child: Text(data['category'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              ]
                                  : selectedReportType == 'invoices' || selectedReportType == 'sales'
                                  ? [
                                Expanded(flex: 2, child: Text(data['invoiceNumber'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 3, child: Text(data['client'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 2, child: Text(data['date'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 2, child: Text('${data['total'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 2, child: Text('${data['profit'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.green))),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditInvoicePage(invoice: data['invoice']),
                                            ),
                                          );
                                        },
                                        tooltip: 'تعديل',
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                                  : [
                                Expanded(flex: 2, child: Text(data['invoiceNumber'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 3, child: Text(data['supplier'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 2, child: Text(data['date'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                                Expanded(flex: 2, child: Text('${data['total'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditInvoicePage extends StatefulWidget {
  final Invoice invoice;

  const EditInvoicePage({super.key, required this.invoice});

  @override
  State<EditInvoicePage> createState() => _EditInvoicePageState();
}

class _EditInvoicePageState extends State<EditInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _invoiceNumberController;
  late String? _selectedClientId;
  late bool _isDeferred;
  late List<InvoiceItem> items;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController = TextEditingController(text: widget.invoice.invoiceNumber);
    _selectedClientId = widget.invoice.clientId;
    _isDeferred = widget.invoice.isDeferred;
    items = List.from(widget.invoice.items);
  }

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

  void _showProductSearchDialog(int index) {
    final TextEditingController _searchController = TextEditingController();
    List<Product> filteredProducts = context.read<DataProvider>().products;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('البحث عن منتج', textAlign: TextAlign.right),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'ابحث بالاسم أو الباركود',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      filteredProducts = context.read<DataProvider>().products.where((product) =>
                      product.name.toLowerCase().contains(value.toLowerCase()) ||
                          product.barcode.contains(value)).toList();
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 400,
                  height: 300,
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, idx) {
                      final product = filteredProducts[idx];
                      return ListTile(
                        title: Text(product.name, textAlign: TextAlign.right),
                        subtitle: Text('الباركود: ${product.barcode}', textAlign: TextAlign.right),
                        onTap: () {
                          setState(() {
                            items[index].productId = product.id;
                            items[index].name = product.name;
                            items[index].categoryId = product.categoryId;
                            items[index].price = product.price;
                            items[index].purchasePrice = product.purchasePrice;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveInvoice(BuildContext context) {
    if (_formKey.currentState!.validate() && _selectedClientId != null) {
      final provider = context.read<DataProvider>();
      // Revert previous quantities
      for (var item in widget.invoice.items) {
        final productIndex = provider.products.indexWhere((p) => p.id == item.productId);
        if (productIndex != -1) {
          final product = provider.products[productIndex];
          provider.updateProduct(Product(
            id: product.id,
            name: product.name,
            barcode: product.barcode,
            price: product.price,
            purchasePrice: product.purchasePrice,
            quantity: product.quantity + item.quantity,
            categoryId: product.categoryId,
          ));
        }
      }
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
      // Save updated invoice
      final updatedInvoice = Invoice(
        id: widget.invoice.id,
        invoiceNumber: _invoiceNumberController.text,
        clientId: _selectedClientId!,
        isDeferred: _isDeferred,
        items: items,
        type: 'outgoing',
        date: DateTime.now(),
      );
      provider.updateInvoice(updatedInvoice);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الفاتورة بنجاح')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final products = provider.products;
    final categories = provider.categories;
    final clients = provider.clients.where((client) => client.type == 'buyer').toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الفاتورة'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                                            items[index].productId = '';
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
                                      child: Row(
                                        children: [
                                          Expanded(
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
                                          IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: () => _showProductSearchDialog(index),
                                          ),
                                        ],
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
                                      child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    super.dispose();
  }
}