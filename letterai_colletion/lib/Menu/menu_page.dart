import 'package:flutter/material.dart';
import 'package:letterai_colletion/Health/health_page.dart';
import 'package:letterai_colletion/Menu/config_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthPage(),
                    fullscreenDialog: true, // ajuda a dar ideia de “modal”, opcional
                  ),
                );
              },
              child:  const Text('Saúde'),
            ),
            const SizedBox(height: 16,),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfigPage(),
                    fullscreenDialog: true, // ajuda a dar ideia de “modal”, opcional
                  ),
                );
              },
              child:  const Text('Configurações'),
            ),
          ],
        ),
      ),
    );
  }
}