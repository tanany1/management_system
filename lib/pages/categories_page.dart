import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common_widgets.dart';
import '../data_provider.dart';
import '../models.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _searchController = TextEditingController();
  List<Category> filteredCategories = [];

  @override
  void initState() {
    super.initState();
    filteredCategories = context.read<DataProvider>().categories;
    _searchController.addListener(() {
      _filterCategories(_searchController.text);
    });
  }

  void _filterCategories(String query) {
    final categories = context.read<DataProvider>().categories;
    setState(() {
      filteredCategories = query.isEmpty
          ? categories
          : categories
          .where((category) => category.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showAddCategoryDialog({Category? category}) {
    final controller = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          category == null ? 'إضافة تصنيف جديد' : 'تعديل التصنيف',
          textAlign: TextAlign.right,
        ),
        content: Form(
          key: GlobalKey<FormState>(),
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: 'اسم التصنيف',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم التصنيف' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final provider = context.read<DataProvider>();
                if (category == null) {
                  provider.addCategory(Category(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: controller.text,
                  ));
                } else {
                  provider.updateCategory(Category(
                    id: category.id,
                    name: controller.text,
                  ));
                }
                setState(() {
                  filteredCategories = provider.categories;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(category == null
                        ? 'تم إضافة التصنيف بنجاح'
                        : 'تم تعديل التصنيف بنجاح'),
                  ),
                );
              }
            },
            child: Text(category == null ? 'إضافة' : 'تعديل'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: Text('هل تريد حذف التصنيف "${category.name}"؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<DataProvider>();
              // Check if category is used by any product
              final isUsed = provider.products.any((p) => p.categoryId == category.id);
              if (isUsed) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا يمكن حذف التصنيف لأنه مستخدم في منتجات')),
                );
                return;
              }
              provider.deleteCategory(category.id);
              setState(() {
                filteredCategories = provider.categories;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف التصنيف بنجاح')),
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
                onPressed: () => _showAddCategoryDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة تصنيف جديد', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
              const Text('التصنيفات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          CommonSearchBar(
            controller: _searchController,
            hintText: 'البحث في التصنيفات...',
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
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الإجراءات',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'اسم التصنيف',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '#',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredCategories.isEmpty
                        ? const Center(
                      child: Text(
                        'لا توجد تصنيفات',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
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
                                      onPressed: () => _showAddCategoryDialog(category: category),
                                      tooltip: 'تعديل',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteCategory(category),
                                      tooltip: 'حذف',
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  category.id,
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