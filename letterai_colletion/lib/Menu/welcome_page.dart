import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:letterai_colletion/Login/login_support.dart';
import 'package:letterai_colletion/Menu/home_page.dart';
import 'package:letterai_colletion/Profile/custom_profile.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            // verifica se o usuário já tem apelido
            final temApelido = await verificarApelido(user);

            if (temApelido) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            } else {
              // não tem apelido → vai para a tela de primeiro acesso
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CustomProfilePage()),
              );
            }
          },
          child: const Text("Começar"),
        ),
      ),
    );
  }
}
