import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:letterai_colletion/Game/cards/card_page.dart';
import 'package:letterai_colletion/Game/cards/complete_collection.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
//import 'package:letterai_colletion/Login/login_page.dart';
import 'package:letterai_colletion/Login/auth_service.dart';
//import 'package:letterai_colletion/main.dart';

class PersonalCollectionPage extends StatelessWidget {
  const PersonalCollectionPage({super.key});

  // Transformando em Stream para atualizações em tempo real
  Stream<List<Map<String, dynamic>>> streamCartas() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid)
        .collection("inventario")
        .doc("itens")
        .collection("colecao")
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coleção')),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: streamCartas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Nenhuma carta encontrada'));
              }

              final cartas = snapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 120 / 180,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: cartas.length,
                itemBuilder: (context, index) {
                  final carta = cartas[index];
                  final imagemPath =
                      carta['imagem'] ?? 'assets/back_cards/0.png';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardPage(cardData: carta),
                        ),
                      );
                    },
                    child: ClipRRect(
                      child: Image.asset(imagemPath, fit: BoxFit.cover),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            right: 0,
            bottom: 40,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CompleteCollectionPage(),
                    fullscreenDialog: true,
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
