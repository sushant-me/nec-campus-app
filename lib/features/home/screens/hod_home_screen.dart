import 'package:flutter/material.dart';

class HodHomeScreen extends StatelessWidget {
  const HodHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HOD Dashboard')),
      body: const Center(
        child: Text('Welcome, HOD!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
