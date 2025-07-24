import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:letterai_colletion/Login/auth_service.dart';
//import 'package:letterai_colletion/Login/login_page.dart';
import 'package:letterai_colletion/Menu/menu_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Bem vindo, ${user?.displayName ?? 'Usuário'}"),
        ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MenuPage()),
            );
          },
          child:  const Text('Ir para o menu'),
        ),
      ),
    );
  }
}