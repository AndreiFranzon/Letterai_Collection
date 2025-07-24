import 'package:flutter/material.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sua saúde')),
      body: const Center(
        child: Text('Oi meu chapam')
        ),
    );
  }
}