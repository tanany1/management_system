import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedReportType = 'inventory';
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

    if (selectedReportType == 'sales') {
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
          orElse: () => Category(id: 'unknown', name: 'غير مصنف'), // Fallback category
        ).name,
      })
          .toList();
    }

    return Padding(
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
                  selectedReportType == 'sales'
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
                        Expanded(flex: 2, child: Text('التصنيف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('الكمية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('سعر الشراء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('سعر البيع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text('اسم المنتج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ]
                          : selectedReportType == 'sales'
                          ? const [
                        Expanded(flex: 2, child: Text('الربح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('الإجمالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text('العميل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('رقم الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ]
                          : const [
                        Expanded(flex: 2, child: Text('الإجمالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text('المورد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('رقم الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
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
                              Expanded(flex: 2, child: Text(data['category'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 2, child: Text(data['quantity'].toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: data['quantity'] < 5 ? Colors.red : Colors.black))),
                              Expanded(flex: 2, child: Text('${data['purchasePrice'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 2, child: Text('${data['price'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 3, child: Text(data['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                            ]
                                : selectedReportType == 'sales'
                                ? [
                              Expanded(flex: 2, child: Text('${data['profit'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.green))),
                              Expanded(flex: 2, child: Text('${data['total'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 2, child: Text(data['date'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 3, child: Text(data['client'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 2, child: Text(data['invoiceNumber'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                            ]
                                : [
                              Expanded(flex: 2, child: Text('${data['total'].toStringAsFixed(2)} ج.م', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 2, child: Text(data['date'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 3, child: Text(data['supplier'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 2, child: Text(data['invoiceNumber'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
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
    );
  }
}