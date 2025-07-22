import 'package:flutter/material.dart';
// 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
//import 'package:letterai_colletion/Menu/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  void _login() async {
    await _authService.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _login,
          icon: const Icon(Icons.login),
          label: const Text("Fazer login com Google")
        ),
      ),
    );
  }
}