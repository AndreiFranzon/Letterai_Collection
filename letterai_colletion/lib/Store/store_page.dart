import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:letterai_colletion/Boosters/buy_function.dart';
import 'package:letterai_colletion/Boosters/sorting_function.dart';
import 'package:letterai_colletion/Models/pacote.dart';

/*class Pacote {
  final int id;
  final String nome;
  final int valor;
  final String moeda;
  final String imagem;

  Pacote({
    required this.id,
    required this.nome,
    required this.valor,
    required this.moeda,
    required this.imagem,
  });

  factory Pacote.fromMap(Map<String, dynamic> map) {
    return Pacote(
      id: map["id"],
      nome: map["nome"],
      valor: map["valor"],
      moeda: map["moeda"],
      imagem: map["imagem"],
    );
  }
}*/

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  Future<List<Pacote>> buscarPacotes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("pacotes").get();
    return snapshot.docs.map((doc) => Pacote.fromMap(doc.data())).toList();
  }

  void _abrirDetalhesPacote(BuildContext context, Pacote pacote) {
  final iconeMoeda =
      pacote.moeda == "purple"
          ? "assets/sprites_sistema/purple_coin.png"
          : "assets/sprites_sistema/yellow_coin.png";

  bool comprado = false; // controla se o pacote já foi comprado

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          pacote.imagem,
                          height: 500,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  comprado
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                abrirPacote(pacote);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                "Abrir",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                final inventory = InventoryFunction();
                                await inventory.savePackage(user.uid, pacote, context);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                "Guardar",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            final buyFunction = BuyFunction();
                            bool sucesso = await buyFunction.buyBooster(context, user.uid, pacote);

                            if (sucesso) {
                              setState(() {
                                comprado = true;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(iconeMoeda, width: 30, height: 30),
                              const SizedBox(width: 8),
                              Text(
                                "${pacote.valor}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loja")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Pacote>>(
          future: buscarPacotes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Erro ao carregar pacotes: ${snapshot.error}"),
              );
            }

            final pacotes = snapshot.data ?? [];

            return GridView.builder(
              itemCount: pacotes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                final pacote = pacotes[index];

                final iconeMoeda =
                    pacote.moeda == "purple"
                        ? "assets/sprites_sistema/purple_coin.png"
                        : "assets/sprites_sistema/yellow_coin.png";

                return Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _abrirDetalhesPacote(context, pacote),
                        child: Image.asset(pacote.imagem, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: () => _abrirDetalhesPacote(context, pacote),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(iconeMoeda, width: 30, height: 30),
                          const SizedBox(width: 6),
                          Text(
                            "${pacote.valor}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
