import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common_widgets.dart';
import '../data_provider.dart';
import '../models.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = context.read<DataProvider>().products;
    _searchController.addListener(() {
      _filterProducts(_searchController.text);
    });
  }

  void _filterProducts(String query) {
    final products = context.read<DataProvider>().products;
    setState(() {
      filteredProducts = query.isEmpty
          ? products
          : products
          .where((product) =>
      product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.barcode.contains(query))
          .toList();
    });
  }

  void _showAddProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(product: product),
    ).then((newProduct) {
      if (newProduct != null) {
        final provider = context.read<DataProvider>();
        if (product == null) {
          provider.addProduct(newProduct);
        } else {
          provider.updateProduct(newProduct);
        }
        setState(() {
          filteredProducts = provider.products;
        });
      }
    });
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: Text('هل تريد حذف المنتج "${product.name}"؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<DataProvider>().deleteProduct(product.id);
              setState(() {
                filteredProducts = context.read<DataProvider>().products;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف المنتج بنجاح')),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة منتج جديد', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const Text(
                'المنتجات',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CommonSearchBar(
            controller: _searchController,
            hintText: 'البحث في المنتجات...',
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
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('الإجراءات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('الكمية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('سعر الشراء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('سعر البيع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('الباركود', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text('اسم المنتج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 1, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? const Center(child: Text('لا توجد منتجات', style: TextStyle(fontSize: 16, color: Colors.grey)))
                        : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: product.quantity < 5 ? Colors.red.shade50 : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddProductDialog(product: product),
                                      tooltip: 'تعديل',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteProduct(product),
                                      tooltip: 'حذف',
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  product.quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: product.quantity < 5 ? Colors.red : Colors.black,
                                    fontWeight: product.quantity < 5 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${product.purchasePrice.toStringAsFixed(2)} ج.م',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${product.price.toStringAsFixed(2)} ج.م',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  product.barcode,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  product.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  product.id,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AddProductDialog extends StatefulWidget {
  final Product? product;

  const AddProductDialog({super.key, this.product});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _quantityController;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _purchasePriceController = TextEditingController(text: widget.product?.purchasePrice.toString() ?? '');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString() ?? '');
    _selectedCategoryId = widget.product?.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<DataProvider>().categories;

    return AlertDialog(
      title: Text(
        widget.product == null ? 'إضافة منتج جديد' : 'تعديل المنتج',
        textAlign: TextAlign.right,
      ),
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
                decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم المنتج' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
                items: categories
                    .map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name, textAlign: TextAlign.right),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategoryId = value),
                validator: (value) => value == null ? 'يرجى اختيار تصنيف' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'الباركود', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال الباركود' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سعر البيع (ج.م)', border: OutlineInputBorder()),
                validator: (value) =>
                value!.isEmpty || double.tryParse(value) == null ? 'يرجى إدخال سعر صحيح' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purchasePriceController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سعر الشراء (ج.م)', border: OutlineInputBorder()),
                validator: (value) =>
                value!.isEmpty || double.tryParse(value) == null ? 'يرجى إدخال سعر شراء صحيح' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                validator: (value) =>
                value!.isEmpty || int.tryParse(value) == null ? 'يرجى إدخال كمية صحيحة' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
              final product = Product(
                id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                barcode: _barcodeController.text,
                price: double.parse(_priceController.text),
                purchasePrice: double.parse(_purchasePriceController.text),
                quantity: int.parse(_quantityController.text),
                categoryId: _selectedCategoryId!,
              );
              Navigator.pop(context, product);
            }
          },
          child: Text(widget.product == null ? 'إضافة' : 'تعديل'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}