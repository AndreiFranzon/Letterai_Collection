//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:letterai_colletion/Profile/profile_page.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:letterai_colletion/Profile/profile_page.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:letterai_colletion/Database_Support/pontos_provider.dart';
import 'package:letterai_colletion/Menu/menu_page.dart';
import 'package:letterai_colletion/Game/cards/personal_collection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  final double fundoTop = 20;
  final double fundoLeft = -35;

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
        toolbarHeight: 120,
        // Para caber a barra de XP e as moedas, usamos Column
        title:
            pontosProvider.carregando
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de XP com nível e avatar
                    Row(
                      children: [
                        // Círculo do nível
                        Container(
                          width: 40,
                          height: 40,
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Barra de XP com texto sobreposto
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Barra de progresso
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        pontosProvider.xp /
                                        (50 + (50 * pontosProvider.nivel)),
                                    backgroundColor: Colors.transparent,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.redAccent,
                                        ),
                                  ),
                                ),
                              ),
                              // Texto sobreposto
                              Text(
                                '${pontosProvider.xp} / ${50 + (50 * pontosProvider.nivel)} XP',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Avatar clicável
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Row das moedas
                    Row(
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
                  ],
                ),
      ),
      body: Stack(
        children: [
          // Fundo principal
          Positioned(
            top: fundoTop,
            left: fundoLeft,
            child: Image.asset(
              'assets/sprites_sistema/stand.png',
              fit: BoxFit.cover,
            ),
          ),

          // Carta ativa central
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
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(-0.20),
                      child: Image.asset(
                        cartaAtiva['imagem'] ?? 'assets/back_cards/0.png',
                        height: 340,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                );
              },
            ),
          ),

          // Botão menu
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

          // Botão da coleção
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
