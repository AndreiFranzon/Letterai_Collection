import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
//import 'package:letterai_colletion/Login/login_page.dart';
import 'package:letterai_colletion/Login/auth_service.dart';
import 'package:letterai_colletion/Profile/daily_goal.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DailyGoalPage(),
                    fullscreenDialog: true, // ajuda a dar ideia de “modal”, opcional
                  ),
                );
              },
              child:  const Text('Metas diárias'),
            ),
          ],
        ),
      ),
    );
  }
}