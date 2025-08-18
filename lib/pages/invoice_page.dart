import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data_provider.dart';
import '../models.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController(
      text: 'INV-${DateTime.now().millisecondsSinceEpoch}');
  String? _selectedClientId;
  bool _isDeferred = false;
  List<InvoiceItem> items = [
    InvoiceItem(
        productId: '',
        name: '',
        categoryId: 'piece',
        quantity: 1,
        price: 0.0,
        purchasePrice: 0.0,
        customPrice: 0.0),
  ];
  String _invoiceState = 'postponed'; // Default state
  double _paidAmount = 0.0; // For partially paid state

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * (item.customPrice > 0 ? item.customPrice : item.price)));
  }

  double get remainingAmount {
    return totalAmount - _paidAmount;
  }

  void addNewItem() {
    setState(() {
      items.add(InvoiceItem(
          productId: '',
          name: '',
          categoryId: 'piece',
          quantity: 1,
          price: 0.0,
          purchasePrice: 0.0,
          customPrice: 0.0));
    });
  }

  void removeItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
      });
    }
  }

  Future<void> _generateAndPrintPDF(
      BuildContext context, String fileName) async {
    final provider = context.read<DataProvider>();
    final client = provider.clients.firstWhere((c) => c.id == _selectedClientId,
        orElse: () => Client(
            id: '',
            name: 'غير محدد',
            phone: '',
            email: '',
            type: 'buyer',
            balance: 0.0));
    final font = pw.Font.ttf((await _loadFontData()));

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('فاتورة الصادر',
                style: pw.TextStyle(
                    font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('رقم الفاتورة: ${_invoiceNumberController.text}',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl),
            pw.Text('العميل: ${client.name}',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl),
            pw.Text('التاريخ: ${DateTime.now().toString().substring(0, 10)}',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl),
            pw.Text('حالة الفاتورة: $_invoiceState',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl),
            pw.Text('المبلغ الإجمالي: ${totalAmount.toStringAsFixed(2)} ج.م',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl),
            pw.Text('المبلغ المدفوع: ${_paidAmount.toStringAsFixed(2)} ج.م',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl),
            pw.Text('المبلغ المتبقي: ${remainingAmount.toStringAsFixed(2)} ج.م',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl),
            pw.SizedBox(height: 20),
            pw.Text('المنتجات:',
                style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
                textDirection: pw.TextDirection.rtl),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FixedColumnWidth(100), // الإجمالي
                1: const pw.FixedColumnWidth(100), // السعر المخصص
                2: const pw.FixedColumnWidth(100), // سعر الوحدة
                3: const pw.FixedColumnWidth(100), // الكمية
                4: const pw.FlexColumnWidth(), // اسم المنتج
                5: const pw.FixedColumnWidth(50), // #
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('الإجمالي',
                        style: pw.TextStyle(font: font),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl),
                    pw.Text('السعر المخصص',
                        style: pw.TextStyle(font: font),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl),
                    pw.Text('سعر الوحدة',
                        style: pw.TextStyle(font: font),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl),
                    pw.Text('الكمية',
                        style: pw.TextStyle(font: font),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl),
                    pw.Text('اسم المنتج',
                        style: pw.TextStyle(font: font),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl),
                    pw.Text('#',
                        style: pw.TextStyle(font: font),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl),
                  ],
                ),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Text(
                          '${(item.quantity * (item.customPrice > 0 ? item.customPrice : item.price)).toStringAsFixed(2)} ج.م',
                          style: pw.TextStyle(font: font),
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.rtl),
                      pw.Text('${item.customPrice.toStringAsFixed(2)} ج.م',
                          style: pw.TextStyle(font: font),
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.rtl),
                      pw.Text('${item.price.toStringAsFixed(2)} ج.م',
                          style: pw.TextStyle(font: font),
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.rtl),
                      pw.Text(item.quantity.toString(),
                          style: pw.TextStyle(font: font),
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.rtl),
                      pw.Text(item.name,
                          style: pw.TextStyle(font: font),
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.rtl),
                      pw.Text('${index + 1}',
                          style: pw.TextStyle(font: font),
                          textAlign: pw.TextAlign.center,
                          textDirection: pw.TextDirection.rtl),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  Future<ByteData> _loadFontData() async {
    return await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
  }

  void _saveInvoice(BuildContext context) {
    if (_formKey.currentState!.validate() && _selectedClientId != null) {
      _showSaveOptionsDialog(context);
    }
  }

  void _showSaveOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خيارات الحفظ', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                _performSave(context, false);
                Navigator.pop(context);
              },
              child: const Text('حفظ فقط'),
            ),
            TextButton(
              onPressed: () {
                _performSave(context, true);
                Navigator.pop(context);
              },
              child: const Text('حفظ وطباعة'),
            ),
          ],
        ),
      ),
    );
  }

  void _performSave(BuildContext context, bool shouldPrint) {
    final provider = context.read<DataProvider>();
    final client = provider.clients.firstWhere((c) => c.id == _selectedClientId);
    if (_isDeferred) {
      provider.updateClient(Client(
        id: client.id,
        name: client.name,
        phone: client.phone,
        email: client.email,
        type: client.type,
        balance: client.balance - (_invoiceState == 'partially paid' ? _paidAmount : totalAmount),
        invoiceState: _invoiceState,
      ));
    }
    for (var item in items) {
      final productIndex =
      provider.products.indexWhere((p) => p.id == item.productId);
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
            SnackBar(
                content: Text('الكمية غير كافية للمنتج: ${product.name}')),
          );
          return;
        }
      }
    }
    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: _invoiceNumberController.text,
      clientId: _selectedClientId!,
      isDeferred: _isDeferred,
      items: items,
      type: 'outgoing',
      date: DateTime.now(),
      state: _invoiceState,
      paidAmount: _paidAmount,
    );
    provider.addInvoice(invoice);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ فاتورة الصادر بنجاح')),
    );
    if (shouldPrint) {
      _generateAndPrintPDF(context, '${_invoiceNumberController.text}.pdf');
    }
    _formKey.currentState?.reset();
    _invoiceNumberController.text =
    'INV-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      items = [
        InvoiceItem(
            productId: '',
            name: '',
            categoryId: 'piece',
            quantity: 1,
            price: 0.0,
            purchasePrice: 0.0,
            customPrice: 0.0)
      ];
      _selectedClientId = null;
      _isDeferred = false;
      _invoiceState = 'postponed';
      _paidAmount = 0.0;
    });
  }

  void _showInvoiceDialog(BuildContext context) {
    final provider = context.read<DataProvider>();
    final client = provider.clients.firstWhere((c) => c.id == _selectedClientId,
        orElse: () => Client(
            id: '',
            name: 'غير محدد',
            phone: '',
            email: '',
            type: 'buyer',
            balance: 0.0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل فاتورة الصادر', textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('رقم الفاتورة: ${_invoiceNumberController.text}',
                  textAlign: TextAlign.right),
              Text('العميل: ${client.name}', textAlign: TextAlign.right),
              Text('التاريخ: ${DateTime.now().toString().substring(0, 10)}',
                  textAlign: TextAlign.right),
              Text('حالة الفاتورة: $_invoiceState', textAlign: TextAlign.right),
              Text('المبلغ الإجمالي: ${totalAmount.toStringAsFixed(2)} ج.م',
                  textAlign: TextAlign.right),
              Text('المبلغ المدفوع: ${_paidAmount.toStringAsFixed(2)} ج.م',
                  textAlign: TextAlign.right),
              Text('المبلغ المتبقي: ${remainingAmount.toStringAsFixed(2)} ج.م',
                  textAlign: TextAlign.right),
              const SizedBox(height: 20),
              const Text('المنتجات:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${index + 1}. ${item.name} - الكمية: ${item.quantity} - السعر: ${(item.customPrice > 0 ? item.customPrice : item.price).toStringAsFixed(2)} ج.م - الإجمالي: ${(item.quantity * (item.customPrice > 0 ? item.customPrice : item.price)).toStringAsFixed(2)} ج.م',
                    textAlign: TextAlign.right,
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text('المبلغ الإجمالي: ${totalAmount.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right),
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
                      filteredProducts = context
                          .read<DataProvider>()
                          .products
                          .where((product) =>
                      product.name
                          .toLowerCase()
                          .contains(value.toLowerCase()) ||
                          product.barcode.contains(value))
                          .toList();
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
                        subtitle: Text('الباركود: ${product.barcode}',
                            textAlign: TextAlign.right),
                        onTap: () {
                          setState(() {
                            items[index].productId = product.id;
                            items[index].name = product.name;
                            items[index].categoryId = product.categoryId;
                            items[index].price = product.price;
                            items[index].purchasePrice = product.purchasePrice;
                            items[index].customPrice = product.price;
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
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final products = provider.products;
    final categories = provider.categories;
    final clients =
    provider.clients.where((client) => client.type == 'buyer').toList();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
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
                        _invoiceNumberController.text =
                        'INV-${DateTime.now().millisecondsSinceEpoch}';
                        setState(() {
                          items = [
                            InvoiceItem(
                                productId: '',
                                name: '',
                                categoryId: 'piece',
                                quantity: 1,
                                price: 0.0,
                                purchasePrice: 0.0,
                                customPrice: 0.0)
                          ];
                          _selectedClientId = null;
                          _isDeferred = false;
                          _invoiceState = 'postponed';
                          _paidAmount = 0.0;
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('إنشاء فاتورة صادر جديدة',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _selectedClientId != null &&
                          items.every((item) => item.productId.isNotEmpty)
                          ? () => _generateAndPrintPDF(
                          context, '${_invoiceNumberController.text}.pdf')
                          : null,
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text('طباعة/تصدير PDF',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                    ),
                  ],
                ),
                const Text('الصادر',
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5)
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'ملخص فاتورة الصادر',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
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
                              validator: (value) => value!.isEmpty
                                  ? 'يرجى إدخال رقم الفاتورة'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedClientId,
                              decoration: const InputDecoration(
                                  labelText: 'العميل (مشتري)',
                                  border: OutlineInputBorder()),
                              items: clients
                                  .map((client) => DropdownMenuItem(
                                value: client.id,
                                child: Text(client.name,
                                    textAlign: TextAlign.right),
                              ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedClientId = value),
                              validator: (value) =>
                              value == null ? 'يرجى اختيار عميل' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: _invoiceState == 'fully paid',
                            onChanged: (value) => setState(() {
                              _invoiceState = 'fully paid';
                              _paidAmount = totalAmount;
                            }),
                          ),
                          const Text('خالص',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          Checkbox(
                            value: _invoiceState == 'partially paid',
                            onChanged: (value) => setState(() {
                              _invoiceState = 'partially paid';
                            }),
                          ),
                          const Text('جزئي',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          Checkbox(
                            value: _invoiceState == 'postponed',
                            onChanged: (value) => setState(() {
                              _invoiceState = 'postponed';
                              _paidAmount = 0.0;
                            }),
                          ),
                          const Text('مؤجل',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (_invoiceState == 'partially paid')
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'المبلغ المدفوع',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => double.tryParse(value ?? '') == null || double.parse(value!) < 0
                                ? 'يرجى إدخال مبلغ صحيح'
                                : double.parse(value) > totalAmount
                                ? 'المبلغ المدفوع لا يمكن أن يتجاوز الإجمالي'
                                : null,
                            onChanged: (value) {
                              setState(() {
                                _paidAmount = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'إضافة منتجات',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final filteredProducts =
                            items[index].categoryId.isEmpty
                                ? products
                                : products
                                .where((product) =>
                            product.categoryId ==
                                items[index].categoryId)
                                .toList();
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
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      initialValue:
                                      items[index].quantity.toString(),
                                      decoration: const InputDecoration(
                                        labelText: 'الكمية',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                      int.tryParse(value ?? '') == null ||
                                          int.parse(value!) <= 0
                                          ? 'يرجى إدخال كمية صحيحة'
                                          : null,
                                      onChanged: (value) {
                                        setState(() {
                                          items[index].quantity =
                                              int.tryParse(value) ?? 1;
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
                                      initialValue: items[index].customPrice.toStringAsFixed(2),
                                      decoration: const InputDecoration(
                                        labelText: 'السعر المخصص',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) => double.tryParse(value ?? '') == null || double.parse(value!) < 0
                                          ? 'يرجى إدخال سعر صحيح'
                                          : null,
                                      onChanged: (value) {
                                        setState(() {
                                          items[index].customPrice = double.tryParse(value) ?? items[index].price;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: categories.any((c) =>
                                      c.id == items[index].categoryId)
                                          ? items[index].categoryId
                                          : null,
                                      decoration: const InputDecoration(
                                          labelText: 'التصنيف',
                                          border: OutlineInputBorder()),
                                      items: [
                                        const DropdownMenuItem(
                                            value: null,
                                            child: Text('اختر تصنيف',
                                                textAlign: TextAlign.right)),
                                        ...categories
                                            .map((category) => DropdownMenuItem(
                                          value: category.id,
                                          child: Text(category.name,
                                              textAlign:
                                              TextAlign.right),
                                        )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          items[index].categoryId = value ??
                                              (categories.isNotEmpty
                                                  ? categories[0].id
                                                  : 'piece');
                                          items[index].productId = '';
                                          items[index].name = '';
                                          items[index].price = 0.0;
                                          items[index].purchasePrice = 0.0;
                                          items[index].customPrice = 0.0;
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
                                          child:
                                          DropdownButtonFormField<String>(
                                            value:
                                            items[index].productId.isEmpty
                                                ? null
                                                : items[index].productId,
                                            decoration: const InputDecoration(
                                                labelText: 'المنتج',
                                                border: OutlineInputBorder()),
                                            items: filteredProducts
                                                .map((product) =>
                                                DropdownMenuItem(
                                                  value: product.id,
                                                  child: Text(
                                                      '${product.name} (${product.categoryId})',
                                                      textAlign:
                                                      TextAlign.right),
                                                ))
                                                .toList(),
                                            validator: (value) => value == null
                                                ? 'يرجى اختيار منتج'
                                                : null,
                                            onChanged: (value) {
                                              setState(() {
                                                final selectedProduct =
                                                products.firstWhere(
                                                        (p) => p.id == value);
                                                items[index].productId = value!;
                                                items[index].name =
                                                    selectedProduct.name;
                                                items[index].categoryId =
                                                    selectedProduct.categoryId;
                                                items[index].price =
                                                    selectedProduct.price;
                                                items[index].purchasePrice =
                                                    selectedProduct
                                                        .purchasePrice;
                                                items[index].customPrice =
                                                    selectedProduct.price;
                                              });
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.search),
                                          onPressed: () =>
                                              _showProductSearchDialog(index),
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
                            label: const Text('إضافة منتج',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${totalAmount.toStringAsFixed(2)} ج.م',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                const Text('المبلغ الإجمالي:',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (_invoiceState == 'partially paid' || _invoiceState == 'fully paid')
                              Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_paidAmount.toStringAsFixed(2)} ج.م',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue),
                                      ),
                                      const Text('المبلغ المدفوع:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${remainingAmount.toStringAsFixed(2)} ج.م',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      const Text('المبلغ المتبقي:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _saveInvoice(context),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    child: const Text('حفظ',
                                        style: TextStyle(color: Colors.white)),
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
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    super.dispose();
  }
}