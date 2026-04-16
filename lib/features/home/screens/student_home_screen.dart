import 'package:flutter/material.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Portal')),
      body: const Center(
        child: Text('Welcome, Student!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
