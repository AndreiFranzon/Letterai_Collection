import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:letterai_colletion/Boosters/sorting_function.dart';
import 'package:letterai_colletion/Models/pacote.dart';

/*class Pacote {
  final int id;
  final String nome;
  final String imagem;

  Pacote({required this.id, required this.nome, required this.imagem});

  factory Pacote.fromMap(Map<String, dynamic> map) {
    return Pacote(
      id: map["id"] ?? 0,
      nome: map["nome"] ?? "",
      imagem: map["imagem"] ?? "",
    );
  }
}*/

class Energia {
  final int num;
  final String tipo;
  final String imagem;

  Energia({required this.num, required this.tipo, required this.imagem});

  factory Energia.fromMap(Map<String, dynamic> map) {
    return Energia(
      num: map["num"] ?? 0,
      tipo: map["tipo"] ?? "",
      imagem: map["imagem"] ?? "",
    );
  }
}

class UsuarioItem {
  final int id;
  final int quantidade;

  UsuarioItem({required this.id, required this.quantidade});

  factory UsuarioItem.fromMap(Map<String, dynamic> map, String idField) {
    return UsuarioItem(
      id: map[idField] ?? 0,
      quantidade: map["quantidade"] ?? 0,
    );
  }
}

class InventoryPage extends StatefulWidget {
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final String userId;

  late Future<List<UsuarioItem>> _pacotesInventario;
  late Future<List<UsuarioItem>> _energiasInventario;

  final Map<int, Pacote> _pacotesMaster = {};
  final Map<int, Energia> _energiasMaster = {};

  UsuarioItem? _pacoteSelecionado;

  int? pacoteSelecionado;
  int? energiaSelecionada;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      debugPrint('O usuário não está logado');
      userId = "";
    }

    _pacotesInventario = buscarPacotesInventario();
    _energiasInventario = buscarEnergiasInventario();
    carregarDadosMestres();
  }

  Future<void> carregarDadosMestres() async {
    final pacotesSnap = await _firestore.collection("pacotes").get();
    for (var doc in pacotesSnap.docs) {
      final pacote = Pacote.fromMap(doc.data());
      _pacotesMaster[pacote.id] = pacote;
    }

    final energiasSnap = await _firestore.collection("energias").get();
    for (var doc in energiasSnap.docs) {
      final energia = Energia.fromMap(doc.data());
      debugPrint(
        "Energia carregada -> id: ${energia.num}, nome: ${energia.tipo}",
      );
      _energiasMaster[energia.num] = energia;
    }

    setState(() {});
  }

  Future<List<UsuarioItem>> buscarPacotesInventario() async {
    final snapshot =
        await _firestore
            .collection("usuarios")
            .doc(userId)
            .collection("inventario")
            .doc("itens")
            .collection("pacotes")
            .get();

    return snapshot.docs
        .map((doc) => UsuarioItem.fromMap(doc.data(), "id"))
        .where((item) => item.quantidade >0)
        .toList();
  }

  Future<List<UsuarioItem>> buscarEnergiasInventario() async {
    final snapshot =
        await _firestore
            .collection("usuarios")
            .doc(userId)
            .collection("inventario")
            .doc("itens")
            .collection("energias")
            .get();

    return snapshot.docs
        .map((doc) => UsuarioItem.fromMap(doc.data(), "energiaId"))
        .where((item) => item.quantidade >0)
        .toList();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildGridPacotes(List<UsuarioItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 120 / 180,
      ),
      itemBuilder: (context, index) {
        final usuarioItem = items[index];
        final pacote = _pacotesMaster[usuarioItem.id];

        if (pacote == null) return const SizedBox();

        return GestureDetector(
          onTap: () {
            setState(() {
              _pacoteSelecionado = usuarioItem;
            });
          },
          child: Column(
            children: [
              Expanded(child: Image.asset(pacote.imagem, fit: BoxFit.cover)),
              const SizedBox(height: 4),
              Text(
                "x${usuarioItem.quantidade}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridEnergias(List<UsuarioItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 120 / 180,
      ),
      itemBuilder: (context, index) {
        final usuarioItem = items[index];
        final energia = _energiasMaster[usuarioItem.id];

        if (energia == null) return const SizedBox();

        return GestureDetector(
          onTap: () {
            setState(() {
              energiaSelecionada = usuarioItem.id;
            });
          },
          child: Column(
            children: [
              Expanded(child: Image.asset(energia.imagem, fit: BoxFit.cover)),
              const SizedBox(height: 4),
              Text(
                "x${usuarioItem.quantidade}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventário")),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Pacotes"),
                  FutureBuilder<List<UsuarioItem>>(
                    future: _pacotesInventario,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildGridPacotes(snapshot.data!);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Energias"),
                  FutureBuilder<List<UsuarioItem>>(
                    future: _energiasInventario,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildGridEnergias(snapshot.data!);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Overlay para Pacote selecionado
          if (_pacoteSelecionado != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _pacoteSelecionado = null;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        _pacotesMaster[_pacoteSelecionado!.id]!.imagem,
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.height * 0.5,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (_pacoteSelecionado == null) return;

                          // Abre o pacote no inventário
                          await abrirPacoteInventario(_pacoteSelecionado!);

                          // Atualiza o inventário para refletir a nova quantidade
                          final pacotesAtualizados =
                              await buscarPacotesInventario();

                          setState(() {
                            _pacotesInventario = Future.value(
                              pacotesAtualizados
                                  .where((item) => item.quantidade > 0)
                                  .toList(),
                            );
                            _pacoteSelecionado = null; // Fecha o overlay
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(140, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Abrir",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Overlay para Energia selecionada
          if (energiaSelecionada != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    energiaSelecionada = null;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  alignment: Alignment.center,
                  child: Image.asset(
                    _energiasMaster[energiaSelecionada!]!.imagem,
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
