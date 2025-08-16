import 'package:flutter/material.dart';
import 'package:management_system/pages/home_page.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'hive_service.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initHive();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataProvider()..loadInitialData(),
      child: MaterialApp(
        title: 'نظام إدارة الفواتير',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // Remove fontFamily if ArabicFont.ttf is not available
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 14),
            headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}