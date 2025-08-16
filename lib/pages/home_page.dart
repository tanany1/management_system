import 'package:flutter/material.dart';
import 'package:management_system/pages/categories_page.dart';
import 'incoming_invoice_page.dart';
import 'inventory_page.dart';
import 'invoice_page.dart';
import 'clients_page.dart';
import 'products_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const InvoicePage(),
    const ClientsPage(),
    const ProductsPage(),
    const ReportsPage(),
    const SettingsPage(),
    const CategoriesPage(),
    const IncomingInvoicePage(),
    const InventoryPage(),
  ];

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.receipt_long, 'title': 'الفواتير', 'color': Colors.blue},
    {'icon': Icons.people, 'title': 'العملاء', 'color': Colors.green},
    {'icon': Icons.inventory, 'title': 'المنتجات', 'color': Colors.orange},
    {'icon': Icons.analytics, 'title': 'التقارير', 'color': Colors.purple},
    {'icon': Icons.settings, 'title': 'الإعدادات', 'color': Colors.grey},
    {'icon': Icons.category, 'title': 'التصنيفات', 'color': Colors.teal},
    {'icon': Icons.receipt, 'title': 'الوارد', 'color': Colors.cyan},
    {'icon': Icons.store, 'title': 'المخزن', 'color': Colors.brown},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Main content area
          Expanded(
            child: pages[selectedIndex],
          ),
          // Right sidebar menu
          Container(
            width: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6A5ACD), Color(0xFF4B0082)],
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'نظام إدارة الفواتير',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.business, color: Colors.white),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                // Menu items
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            menuItems[index]['icon'],
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          title: Text(
                            menuItems[index]['title'],
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Footer info
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    children: [
                      Divider(color: Colors.white24),
                      Text(
                        'المستخدم: Admin',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}