import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SleepPage extends StatelessWidget {
  const SleepPage({super.key});

  //final user = FirebaseAuth.instance.currentUser;
      //if (user == null) {
        //debugPrint('O usuário não está logado');
        //return;
      //}

  //final userId = user.uid;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Seu soninho')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          ],
        ),
      ),
    );
  }
}