//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:letterai_colletion/Profile/profile_page.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:letterai_colletion/Database_Support/pontos_provider.dart';
import 'package:letterai_colletion/Menu/menu_page.dart';
import 'package:letterai_colletion/Game/cards/personal_collection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Stream<Map<String, dynamic>?> _carregarCartaAtiva() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid)
        .collection("inventario")
        .doc("itens")
        .collection("carta_ativa")
        .doc("selecionada")
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data()!;
          data['id'] = doc.id;
          return data;
        });
  }

  @override
  Widget build(BuildContext context) {
    final pontosProvider = Provider.of<PontosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title:
            pontosProvider.carregando
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/sprites_sistema/yellow_coin.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${pontosProvider.pontosAmarelos}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/sprites_sistema/purple_coin.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${pontosProvider.pontosRoxos}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
      body: Stack(
        children: [
          Center(
            child: StreamBuilder<Map<String, dynamic>?>(
              stream: _carregarCartaAtiva(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text(
                    'Nenhuma carta ativa',
                    style: TextStyle(fontSize: 24),
                  );
                }

                final cartaAtiva = snapshot.data!;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspectiva 3D
                            ..rotateX(-0.20), // inclinação para trás
                      child: Image.asset(
                        cartaAtiva['imagem'] ?? 'assets/back_cards/0.png',
                        height: 320,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                );
              },
            ),
          ),

          // Botão menu alinhado na parte inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MenuPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Botão da coleção, acima do botão menu
          Positioned(
            right: 0,
            bottom: 100,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalCollectionPage(),
                  ),
                );
              },
              child: Image.asset(
                'assets/back_cards/0.png',
                width: 100,
                height: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
