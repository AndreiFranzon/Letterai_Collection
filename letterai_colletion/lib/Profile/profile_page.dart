import 'package:flutter/material.dart';
import 'package:letterai_colletion/Database_Support/pontos_provider.dart';
import 'package:letterai_colletion/Friends/friends_page.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
//import 'package:letterai_colletion/Login/login_page.dart';
import 'package:letterai_colletion/Login/auth_service.dart';
import 'package:letterai_colletion/Profile/daily_goal.dart';
import 'package:letterai_colletion/Profile/inventory.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pontosProvider = Provider.of<PontosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100, // altura maior para caber o círculo e barra de XP
        title: pontosProvider.carregando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                children: [
                  // Círculo do nível
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${pontosProvider.nivel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Barra de XP
                  Expanded(
                    child: Container(
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pontosProvider.xp /
                              (50 + (50 * pontosProvider.nivel)),
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.redAccent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      body: Stack(
        children: [
          // Conteúdo central (Metas e Inventário)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DailyGoalPage(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: const Text('Metas diárias'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryPage(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: const Text('Inventário'),
                ),
              ],
            ),
          ),

          // Botão de amigos no topo direito, abaixo da AppBar
          Positioned(
            top: -8, // logo abaixo da AppBar
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FriendsPage()),
                );
              },
              child: Image.asset(
                'assets/sprites_sistema/friend.png',
                width: 60,
                height: 60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
