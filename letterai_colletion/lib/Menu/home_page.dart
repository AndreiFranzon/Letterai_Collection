import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:letterai_colletion/Login/auth_service.dart';
//import 'package:letterai_colletion/Login/login_page.dart';
import 'package:letterai_colletion/Menu/menu_page.dart';

Future<void> solicitarPermissoes() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.activityRecognition,
    Permission.sensors,
    Permission.location,
  ].request();

  statuses.forEach((permissao, status) {
    if (status.isDenied) {
      print('Permissão negada para: $permissao');
    }
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    solicitarPermissoes();
  }

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