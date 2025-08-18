import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  final TextEditingController _searchController = TextEditingController();

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

// Filter report data based on selected type and date range
    if (selectedReportType == 'invoices') {
      reportData = invoices
          .where((invoice) => invoice.type == 'outgoing')
          .map((invoice) {
            double invoiceTotal = invoice.items.fold(
                0.0,
                (sum, item) =>
                    sum +
                    (item.quantity *
                        (item.customPrice > 0
                            ? item.customPrice
                            : item.price)));
            double invoiceCost = invoice.items.fold(
                0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
            if ((startDate == null || invoice.date.isAfter(startDate!)) &&
                (endDate == null ||
                    invoice.date
                        .isBefore(endDate!.add(const Duration(days: 1))))) {
              totalSales += invoiceTotal;
              totalProfit += invoiceTotal - invoiceCost;
              return {
                'invoiceNumber': invoice.invoiceNumber,
                'client': clients
                    .firstWhere((c) => c.id == invoice.clientId,
                        orElse: () => Client(
                            id: '',
                            name: 'غير محدد',
                            phone: '',
                            email: '',
                            type: 'buyer',
                            balance: 0.0))
                    .name,
                'date': invoice.date.toString().substring(0, 10),
                'total': invoiceTotal,
                'profit': invoiceTotal - invoiceCost,
                'invoice': invoice,
                'state': invoice.state ?? 'postponed',
                'paidAmount': invoice.paidAmount ?? 0.0,
              };
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } else if (selectedReportType == 'sales') {
      reportData = invoices
          .where((invoice) => invoice.type == 'outgoing')
          .map((invoice) {
            double invoiceTotal = invoice.items.fold(
                0.0,
                (sum, item) =>
                    sum +
                    (item.quantity *
                        (item.customPrice > 0
                            ? item.customPrice
                            : item.price)));
            double invoiceCost = invoice.items.fold(
                0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
            if ((startDate == null || invoice.date.isAfter(startDate!)) &&
                (endDate == null ||
                    invoice.date
                        .isBefore(endDate!.add(const Duration(days: 1))))) {
              totalSales += invoiceTotal;
              totalProfit += invoiceTotal - invoiceCost;
              return {
                'invoiceNumber': invoice.invoiceNumber,
                'client': clients
                    .firstWhere((c) => c.id == invoice.clientId,
                        orElse: () => Client(
                            id: '',
                            name: 'غير محدد',
                            phone: '',
                            email: '',
                            type: 'buyer',
                            balance: 0.0))
                    .name,
                'date': invoice.date.toString().substring(0, 10),
                'total': invoiceTotal,
                'profit': invoiceTotal - invoiceCost,
                'state': invoice.state ?? 'postponed',
                'paidAmount': invoice.paidAmount ?? 0.0,
              };
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } else if (selectedReportType == 'purchases') {
      reportData = invoices
          .where((invoice) => invoice.type == 'incoming')
          .map((invoice) {
            double invoiceTotal = invoice.items.fold(
                0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
            if ((startDate == null || invoice.date.isAfter(startDate!)) &&
                (endDate == null ||
                    invoice.date
                        .isBefore(endDate!.add(const Duration(days: 1))))) {
              totalPurchases += invoiceTotal;
              return {
                'invoiceNumber': invoice.invoiceNumber,
                'supplier': clients
                    .firstWhere((c) => c.id == invoice.clientId,
                        orElse: () => Client(
                            id: '',
                            name: 'غير محدد',
                            phone: '',
                            email: '',
                            type: 'supplier',
                            balance: 0.0))
                    .name,
                'date': invoice.date.toString().substring(0, 10),
                'total': invoiceTotal,
              };
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } else if (selectedReportType == 'inventory') {
      reportData = products.map((product) {
        return {
          'name': product.name,
          'quantity': product.quantity,
          'price': product.price,
          'purchasePrice': product.purchasePrice,
          'category': provider.categories
              .firstWhere(
                (c) => c.id == product.categoryId,
                orElse: () => Category(id: 'unknown', name: 'غير مصنف'),
              )
              .name,
        };
      }).toList();
    }

// Apply search filter for client/supplier names
    final filteredReportData = reportData.where((data) {
      if (data.containsKey('client') && _searchController.text.isNotEmpty) {
        return data['client']
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      } else if (data.containsKey('supplier') &&
          _searchController.text.isNotEmpty) {
        return data['supplier']
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('التقارير',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: child!,
                            );
                          },
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
                  onSelected: (selected) =>
                      setState(() => selectedReportType = 'invoices'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('المخزن'),
                  selected: selectedReportType == 'inventory',
                  onSelected: (selected) =>
                      setState(() => selectedReportType = 'inventory'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('المبيعات'),
                  selected: selectedReportType == 'sales',
                  onSelected: (selected) =>
                      setState(() => selectedReportType = 'sales'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('المشتريات'),
                  selected: selectedReportType == 'purchases',
                  onSelected: (selected) =>
                      setState(() => selectedReportType = 'purchases'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedReportType != 'inventory')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    selectedReportType == 'sales' ||
                            selectedReportType == 'invoices'
                        ? 'إجمالي المبيعات: ${totalSales.toStringAsFixed(2)} ج.م | إجمالي الربح: ${totalProfit.toStringAsFixed(2)} ج.م'
                        : 'إجمالي المشتريات: ${totalPurchases.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'البحث بالعميل/المورد',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
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
                                Expanded(
                                    flex: 3,
                                    child: Text('اسم المنتج',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    flex: 2,
                                    child: Text('سعر البيع',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    flex: 2,
                                    child: Text('سعر الشراء',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    flex: 2,
                                    child: Text('الكمية',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    flex: 2,
                                    child: Text('التصنيف',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center)),
                              ]
                            : selectedReportType == 'invoices' ||
                                    selectedReportType == 'sales'
                                ? const [
                                    Expanded(
                                        flex: 2,
                                        child: Text('رقم الفاتورة',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 3,
                                        child: Text('العميل',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('التاريخ',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('الإجمالي',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('الربح',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('حالة الدفع',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('المبلغ المدفوع',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('الإجراءات',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                  ]
                                : const [
                                    Expanded(
                                        flex: 2,
                                        child: Text('رقم الفاتورة',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 3,
                                        child: Text('المورد',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('التاريخ',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Expanded(
                                        flex: 2,
                                        child: Text('الإجمالي',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                  ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredReportData.isEmpty
                          ? const Center(
                              child: Text('لا توجد بيانات للتقرير',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)))
                          : ListView.builder(
                              itemCount: filteredReportData.length,
                              itemBuilder: (context, index) {
                                final data = filteredReportData[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: selectedReportType == 'inventory'
                                        ? [
                                            Expanded(
                                                flex: 3,
                                                child: Text(data['name'],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    '${data['price'].toStringAsFixed(2)} ج.م',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 14))),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    '${data['purchasePrice'].toStringAsFixed(2)} ج.م',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 14))),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    data['quantity'].toString(),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            data['quantity'] < 5
                                                                ? Colors.red
                                                                : Colors
                                                                    .black))),
                                            Expanded(
                                                flex: 2,
                                                child: Text(data['category'],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 14))),
                                          ]
                                        : selectedReportType == 'invoices' ||
                                                selectedReportType == 'sales'
                                            ? [
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                        data['invoiceNumber'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 3,
                                                    child: Text(data['client'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(data['date'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                        '${data['total'].toStringAsFixed(2)} ج.م',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                        '${data['profit'].toStringAsFixed(2)} ج.م',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.green))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(data['state'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                        '${data['paidAmount'].toStringAsFixed(2)} ج.م',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit,
                                                            color: Colors.blue),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  EditInvoicePage(
                                                                      invoice: data[
                                                                          'invoice']),
                                                            ),
                                                          ).then((value) {
                                                            if (value == null) {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title: const Text(
                                                                      'تأكيد الخروج',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .right),
                                                                  content: const Text(
                                                                      'هل تريد الحفظ والخروج أم الخروج بدون حفظ؟',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .right),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        final updatedInvoice =
                                                                            data['invoice'];
                                                                        updatedInvoice.invoiceNumber +=
                                                                            ' (Edited)';
                                                                        context
                                                                            .read<DataProvider>()
                                                                            .updateInvoice(updatedInvoice);
                                                                        Navigator.pop(
                                                                            context);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                          'حفظ وخروج'),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                          'خروج بدون حفظ'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                          });
                                                        },
                                                        tooltip: 'تعديل',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.print,
                                                            color:
                                                                Colors.orange),
                                                        onPressed: () {
                                                          _generateAndPrintPDF(
                                                              context,
                                                              '${data['invoiceNumber']}.pdf',
                                                              data['invoice']);
                                                        },
                                                        tooltip: 'طباعة',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ]
                                            : [
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                        data['invoiceNumber'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                        data['supplier'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(data['date'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                        '${data['total'].toStringAsFixed(2)} ج.م',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 14))),
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

  Future<void> _generateAndPrintPDF(
      BuildContext context, String fileName, Invoice invoice) async {
    try {
      final provider = context.read<DataProvider>();
      final client = provider.clients.firstWhere(
          (c) => c.id == invoice.clientId,
          orElse: () => Client(
              id: '',
              name: 'غير محدد',
              phone: '',
              email: '',
              type: 'buyer',
              balance: 0.0));
      final font = await pw.Font.ttf((await DefaultAssetBundle.of(context)
          .load('assets/fonts/NotoSansArabic-Regular.ttf')));

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
                      font: font,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('رقم الفاتورة: ${invoice.invoiceNumber}',
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl),
              pw.Text('العميل: ${client.name}',
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl),
              pw.Text('التاريخ: ${invoice.date.toString().substring(0, 10)}',
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl),
              pw.Text('حالة الفاتورة: ${invoice.state ?? 'postponed'}',
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl),
              pw.Text(
                  'المبلغ الإجمالي: ${invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * (item.customPrice > 0 ? item.customPrice : item.price))).toStringAsFixed(2)} ج.م',
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl),
              pw.Text(
                  'المبلغ المدفوع: ${(invoice.paidAmount ?? 0.0).toStringAsFixed(2)} ج.م',
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl),
              pw.Text(
                  'المبلغ المتبقي: ${(invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * (item.customPrice > 0 ? item.customPrice : item.price))) - (invoice.paidAmount ?? 0.0)).toStringAsFixed(2)} ج.م',
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl),
              pw.SizedBox(height: 20),
              pw.Text('المنتجات:',
                  style:
                      pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
                  textDirection: pw.TextDirection.rtl),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(100),
                  1: const pw.FixedColumnWidth(100),
                  2: const pw.FixedColumnWidth(100),
                  3: const pw.FixedColumnWidth(100),
                  4: const pw.FlexColumnWidth(),
                  5: const pw.FixedColumnWidth(50),
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
                  ...invoice.items.asMap().entries.map((entry) {
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
          onLayout: (PdfPageFormat format) async => pdf.save(), name: fileName);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خطأ في الطباعة', textAlign: TextAlign.right),
          content:
              Text('حدث خطأ أثناء إنشاء PDF: $e', textAlign: TextAlign.right),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    }
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
  late String _invoiceState;
  late double _paidAmount;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController =
        TextEditingController(text: widget.invoice.invoiceNumber);
    _selectedClientId = widget.invoice.clientId;
    _isDeferred = widget.invoice.isDeferred;
    items = List.from(widget.invoice.items);
    _invoiceState = widget.invoice.state ?? 'postponed';
    _paidAmount = widget.invoice.paidAmount ?? 0.0;
  }

  double get totalAmount {
    return items.fold(
        0.0,
        (sum, item) =>
            sum +
            (item.quantity *
                (item.customPrice > 0 ? item.customPrice : item.price)));
  }

  double get remainingAmount {
    return totalAmount - _paidAmount;
  }

  void addNewItem() {
    setState(() {
      items.add(InvoiceItem(
          productId: '',
          name: '',
          categoryId: '',
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
      for (var item in widget.invoice.items) {
        final productIndex =
            provider.products.indexWhere((p) => p.id == item.productId);
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
      if (_isDeferred) {
        final client =
            provider.clients.firstWhere((c) => c.id == _selectedClientId);
        provider.updateClient(Client(
          id: client.id,
          name: client.name,
          phone: client.phone,
          email: client.email,
          type: client.type,
          balance: client.balance -
              (_invoiceState == 'partially paid' ? _paidAmount : totalAmount),
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
      final updatedInvoice = Invoice(
        id: widget.invoice.id,
        invoiceNumber: _invoiceNumberController.text,
        clientId: _selectedClientId!,
        isDeferred: _isDeferred,
        items: items,
        type: 'outgoing',
        date: DateTime.now(),
        state: _invoiceState,
        paidAmount: _paidAmount,
      );
      provider.updateInvoice(updatedInvoice);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الفاتورة بنجاح')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final products = provider.products;
    final categories = provider.categories;
    final clients =
        provider.clients.where((client) => client.type == 'buyer').toList();

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
                                    onChanged: (value) => setState(
                                        () => _selectedClientId = value),
                                    validator: (value) => value == null
                                        ? 'يرجى اختيار عميل'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isDeferred,
                                  onChanged: (value) =>
                                      setState(() => _isDeferred = value!),
                                ),
                                const Text('دفع مؤجل',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 20),
                                Checkbox(
                                  value: _invoiceState == 'partially paid',
                                  onChanged: (value) => setState(() {
                                    _invoiceState = 'partially paid';
                                    _paidAmount = totalAmount /
                                        2; // Default to half as an example
                                  }),
                                ),
                                const Text('جزئي',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 20),
                                Checkbox(
                                  value: _invoiceState == 'postponed',
                                  onChanged: (value) => setState(() {
                                    _invoiceState = 'postponed';
                                    _paidAmount = 0.0;
                                  }),
                                ),
                                const Text('مؤجل',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_invoiceState == 'partially paid' ||
                                _invoiceState == 'fully paid')
                              TextFormField(
                                initialValue: _paidAmount.toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  labelText: 'المبلغ المدفوع',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'يرجى إدخال المبلغ المدفوع';
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount < 0)
                                    return 'يرجى إدخال قيمة صحيحة';
                                  if (amount > totalAmount)
                                    return 'المبلغ المدفوع يجب أن يكون أقل أو يساوي الإجمالي';
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _paidAmount = double.tryParse(value) ?? 0.0;
                                  });
                                },
                              ),
                            const SizedBox(height: 10),
                            Text(
                                'الإجمالي: ${totalAmount.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(
                                'المتبقي: ${remainingAmount.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            initialValue: items[index].name,
                                            textAlign: TextAlign.right,
                                            decoration: const InputDecoration(
                                              labelText: 'اسم المنتج',
                                              border: OutlineInputBorder(),
                                            ),
                                            onTap: () =>
                                                _showProductSearchDialog(index),
                                            validator: (value) => value!.isEmpty
                                                ? 'يرجى اختيار منتج'
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            initialValue: items[index]
                                                .quantity
                                                .toString(),
                                            textAlign: TextAlign.right,
                                            decoration: const InputDecoration(
                                              labelText: 'الكمية',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty)
                                                return 'يرجى إدخال الكمية';
                                              final qty = int.tryParse(value);
                                              if (qty == null || qty <= 0)
                                                return 'يرجى إدخال كمية صحيحة';
                                              return null;
                                            },
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
                                          flex: 1,
                                          child: TextFormField(
                                            initialValue: items[index]
                                                .customPrice
                                                .toStringAsFixed(2),
                                            textAlign: TextAlign.right,
                                            decoration: const InputDecoration(
                                              labelText: 'سعر مخصص',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                items[index].customPrice =
                                                    double.tryParse(value) ??
                                                        items[index].price;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () => removeItem(index),
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
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  label: const Text('إضافة منتج',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _saveInvoice(context),
                                  child: const Text('حفظ'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('إلغاء',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }
}
