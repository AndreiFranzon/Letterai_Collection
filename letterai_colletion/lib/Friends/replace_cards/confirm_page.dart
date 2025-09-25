import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letterai_colletion/Friends/replace_cards/replace_support.dart';

class ConfirmPage extends StatefulWidget {
  final String amigoUid;
  const ConfirmPage({super.key, required this.amigoUid});

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  List<Map<String, dynamic>> cartasEnviando = [];
  List<Map<String, dynamic>> cartasRecebendo = [];

  @override
  void initState() {
    super.initState();
    _carregarCartas();
  }

  Future<void> _carregarCartas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Cartas que estou enviando
    final enviadaDoc =
        await FirebaseFirestore.instance
            .collection("usuarios")
            .doc(uid)
            .collection("estatisticas")
            .doc("propostas")
            .collection("enviadas")
            .doc(widget.amigoUid)
            .get();

    if (enviadaDoc.exists) {
      final data = enviadaDoc.data()!;
      final cartasMap = Map<String, dynamic>.from(data['cartas'] ?? {});
      cartasEnviando =
          cartasMap.values.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // Cartas que vou receber (contraproposta recebida)
    final recebidaDoc =
        await FirebaseFirestore.instance
            .collection("usuarios")
            .doc(uid)
            .collection("estatisticas")
            .doc("propostas")
            .collection("contraproposta_recebida")
            .doc(widget.amigoUid)
            .get();

    if (recebidaDoc.exists) {
      final data = recebidaDoc.data()!;
      final cartasMap = Map<String, dynamic>.from(data['cartas'] ?? {});
      cartasRecebendo =
          cartasMap.values.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    setState(() {}); // Atualiza a UI
  }

  Widget _buildCartaItem(Map<String, dynamic> carta) {
    final imagem = carta['imagem'] ?? 'assets/back_cards/0.png';
    final nivel = carta['nivel'] ?? 0;
    final pontos = carta['pontos_ganhos'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        leading: SizedBox(
          width: 40,
          height: 70,
          child: Image.asset(imagem, fit: BoxFit.cover),
        ),
        subtitle: Text("Nível: $nivel   |   Pontos: $pontos"),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Confirmar Troca")),
    body: cartasEnviando.isEmpty && cartasRecebendo.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              if (cartasEnviando.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    "Cartas que estou enviando",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...cartasEnviando.map(_buildCartaItem),
                const Divider(thickness: 2),
              ],

              if (cartasRecebendo.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    "Cartas que vou receber",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...cartasRecebendo.map(_buildCartaItem),
                const SizedBox(height: 12),

                // Botão para recusar contraproposta
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await recusarContraproposta(widget.amigoUid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Contraproposta recusada!"),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text("Recusar Contraproposta"),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton(
                  onPressed: () {
                    confirmarTroca(widget.amigoUid);
                  },
                  child: const Text("Confirmar Troca"),
                ),
              ),
            ],
          ),
  );
}

}
