import 'package:flutter/material.dart';
import 'screens/categories_screen.dart';
import 'helpers/category_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database and load default categories if needed
  await CategoryHelper.instance.reloadDefaultCategories();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مشغل الفيديو التعليمي',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Cairo'),
      home: const CategoriesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
