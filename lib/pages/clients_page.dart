import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common_widgets.dart';
import '../data_provider.dart';
import '../models.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _searchController = TextEditingController();
  String selectedType = 'all';
  List<Client> filteredClients = [];

  @override
  void initState() {
    super.initState();
    filteredClients = context.read<DataProvider>().clients;
    _searchController.addListener(() {
      _filterClients(_searchController.text);
    });
  }

  void _filterClients(String query) {
    final clients = context.read<DataProvider>().clients;
    setState(() {
      filteredClients = clients.where((client) {
        final matchesQuery =
            client.name.toLowerCase().contains(query.toLowerCase()) ||
                client.phone.contains(query);
        final matchesType =
            selectedType == 'all' || client.type == selectedType;
        return matchesQuery && matchesType;
      }).toList();
    });
  }

  void _showAddClientDialog({Client? client}) {
    showDialog(
      context: context,
      builder: (context) => AddClientDialog(client: client),
    ).then((newClient) {
      if (newClient != null) {
        final provider = context.read<DataProvider>();
        if (client == null) {
          provider.addClient(newClient);
        } else {
          provider.updateClient(newClient);
        }
        setState(() {
          filteredClients = provider.clients;
        });
      }
    });
  }

  void _deleteClient(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: Text('هل تريد حذف العميل "${client.name}"؟',
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context.read<DataProvider>().deleteClient(client.id);
              setState(() {
                filteredClients = context.read<DataProvider>().clients;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف العميل بنجاح')),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final invoices = provider.invoices;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddClientDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة عميل جديد',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const Text('العملاء',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              ChoiceChip(
                label: const Text('الكل'),
                selected: selectedType == 'all',
                onSelected: (selected) => setState(() {
                  selectedType = 'all';
                  _filterClients(_searchController.text);
                }),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('الموردين'),
                selected: selectedType == 'supplier',
                onSelected: (selected) => setState(() {
                  selectedType = 'supplier';
                  _filterClients(_searchController.text);
                }),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('المشترين'),
                selected: selectedType == 'buyer',
                onSelected: (selected) => setState(() {
                  selectedType = 'buyer';
                  _filterClients(_searchController.text);
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CommonSearchBar(
            controller: _searchController,
            hintText: 'البحث في العملاء...',
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
                      blurRadius: 5),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text('الإجراءات',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 2,
                            child: Text('دور العميل',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 2,
                            child: Text('الرصيد',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 2,
                            child: Text('رقم الهاتف',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 3,
                            child: Text('اسم العميل',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 1,
                            child: Text('#',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredClients.isEmpty
                        ? const Center(
                        child: Text('لا توجد عملاء',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey)))
                        : ListView.builder(
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        final clientInvoices = invoices
                            .where((invoice) =>
                        invoice.clientId == client.id &&
                            invoice.type == 'outgoing')
                            .toList();
                        return ExpansionTile(
                          title: Container(
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
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _showAddClientDialog(
                                                client: client),
                                        tooltip: 'تعديل',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteClient(client),
                                        tooltip: 'حذف',
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    client.type == 'buyer'
                                        ? 'مشتري'
                                        : 'مورد',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${client.balance.toStringAsFixed(2)} ج.م',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: client.balance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    flex: 2,
                                    child: Text(client.phone,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 14))),
                                Expanded(
                                    flex: 3,
                                    child: Text(client.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 1,
                                    child: Text(client.id,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 14))),
                              ],
                            ),
                          ),
                          children: [
                            if (clientInvoices.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('لا توجد فواتير لهذا العميل',
                                    textAlign: TextAlign.center),
                              )
                            else
                              ...clientInvoices.map((invoice) {
                                double invoiceTotal = invoice.items.fold(
                                    0.0,
                                        (sum, item) => sum +
                                        (item.quantity *
                                            (item.customPrice > 0
                                                ? item.customPrice
                                                : item.price)));
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                    borderRadius:
                                    BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                              invoice.invoiceNumber,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                              invoice.date
                                                  .toString()
                                                  .substring(0, 10),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                              '${invoiceTotal.toStringAsFixed(2)} ج.م',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                              invoice.state ?? 'مؤجل',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AddClientDialog extends StatefulWidget {
  final Client? client;

  const AddClientDialog({super.key, this.client});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedType = 'buyer';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _selectedType = widget.client?.type ?? 'buyer';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.client == null ? 'إضافة عميل جديد' : 'تعديل العميل',
          textAlign: TextAlign.right),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                    labelText: 'اسم العميل', border: OutlineInputBorder()),
                validator: (value) =>
                value!.isEmpty ? 'يرجى إدخال اسم العميل' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                    labelText: 'نوع العميل', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'buyer',
                      child: Text('مشتري', textAlign: TextAlign.right)),
                  DropdownMenuItem(
                      value: 'supplier',
                      child: Text('مورد', textAlign: TextAlign.right)),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
                validator: (value) =>
                value == null ? 'يرجى اختيار نوع العميل' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'رقم الهاتف', border: OutlineInputBorder()),
                validator: (value) =>
                value!.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final client = Client(
                id: widget.client?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                phone: _phoneController.text,
                email: '',
                type: _selectedType,
                balance: widget.client?.balance ?? 0.0,
              );
              Navigator.pop(context, client);
            }
          },
          child: Text(widget.client == null ? 'إضافة' : 'تعديل'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}