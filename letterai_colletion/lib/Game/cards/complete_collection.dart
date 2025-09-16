import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CompleteCollectionPage extends StatefulWidget {
  const CompleteCollectionPage({super.key});

  @override
  State<CompleteCollectionPage> createState() => _CompleteCollectionPageState();
}

class _CompleteCollectionPageState extends State<CompleteCollectionPage> {
  int? cartaSelecionada;
  List<String> cartasObtidas = [];
  final totalCartas = 60;

  @override
  void initState() {
    super.initState();
    _carregarCartasObtidas();
  }

  Future<void> _carregarCartasObtidas() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('inventario')
            .doc('itens')
            .collection('cartas_obtidas')
            .doc('lista')
            .get();

    if (doc.exists) {
      setState(() {
        cartasObtidas = List<String>.from(doc['cartas_obtidas'] ?? <String>[]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final obtidas = cartasObtidas.length;
    final progresso = obtidas / totalCartas;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progresso,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  "$obtidas / $totalCartas cartas coletadas (${(progresso * 100).toStringAsFixed(1)}%)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          //Mostra cartas
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    itemCount: totalCartas,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 120 / 180,
                        ),
                    itemBuilder: (context, index) {
                      final cartaId = (index + 1).toString();
                      final possui = cartasObtidas.contains(cartaId);

                      final caminhoImagem =
                          possui
                              ? 'assets/front_cards/$cartaId.png'
                              : 'assets/front_cards_bw/$cartaId.png';

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            cartaSelecionada = index;
                          });
                        },
                        child: Image.asset(caminhoImagem, fit: BoxFit.cover),
                      );
                    },
                  ),
                ),
                if (cartaSelecionada != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          cartaSelecionada = null;
                        });
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.8),
                        alignment: Alignment.center,
                        child: Image.asset(
                          cartasObtidas.contains(
                                (cartaSelecionada! + 1).toString(),
                              )
                              ? 'assets/front_cards/${cartaSelecionada! + 1}.png'
                              : 'assets/front_cards_bw/${cartaSelecionada! + 1}.png',
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.height * 0.8,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
