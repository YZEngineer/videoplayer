import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية')),
      body: const Center(
        child: Text('مرحباً بك', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
