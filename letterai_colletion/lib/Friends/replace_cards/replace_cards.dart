import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letterai_colletion/Friends/replace_cards/replace_support.dart';

class ReplaceCardsPage extends StatefulWidget {
  final String amigoUid;
  const ReplaceCardsPage({super.key, required this.amigoUid});

  @override
  State<ReplaceCardsPage> createState() => _ReplaceCardsPageState();
}

class _ReplaceCardsPageState extends State<ReplaceCardsPage> {
  final Set<String> _selecionadas = {}; // cartas selecionadas para envio
  final TextEditingController _mensagemController = TextEditingController();

  List<Map<String, dynamic>> propostasRecebidas = [];
  String mensagemRemetente = "";
  bool temProposta = false;

  Stream<QuerySnapshot> _streamCartas() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("inventario")
        .doc("itens")
        .collection("colecao")
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _carregarPropostaRecebida();
  }

  Future<void> _carregarPropostaRecebida() async {
    final meuUid = FirebaseAuth.instance.currentUser?.uid;
    if (meuUid == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection("usuarios")
            .doc(meuUid)
            .collection("estatisticas")
            .doc("propostas")
            .collection("recebidas")
            .doc(widget.amigoUid)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      final cartas = Map<String, dynamic>.from(data['cartas'] ?? {});
      setState(() {
        temProposta = true;
        mensagemRemetente = data['mensagemRemetente'] ?? "";
        propostasRecebidas =
            cartas.entries.map((e) {
              final carta = Map<String, dynamic>.from(e.value);
              carta['id'] = e.key;
              return carta;
            }).toList();
      });
    }
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecionar Cartas")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamCartas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhuma carta encontrada."));
          }

          final minhasCartas =
              snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // ===========================
              // Proposta recebida (se existir)
              // ===========================
              // ===========================
              // Proposta recebida (se existir)
              // ===========================
              if (temProposta) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    "Proposta recebida",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (mensagemRemetente.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      mensagemRemetente,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: propostasRecebidas.length,
                  itemBuilder: (context, index) {
                    final carta = propostasRecebidas[index];
                    final imagem = carta['imagem'] ?? 'assets/back_cards/0.png';
                    final nivel = carta['nivel'] ?? 0;
                    final pontos = carta['pontos_ganhos'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                  },
                ),

                // Botão para recusar proposta
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      // Chama a função que criamos
                      await recusarProposta(widget.amigoUid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Proposta recusada com sucesso!"),
                        ),
                      );
                      setState(() {
                        // Atualiza a UI removendo a proposta
                        temProposta = false;
                        propostasRecebidas.clear();
                        mensagemRemetente = "";
                      });
                    },
                    child: const Text("Recusar proposta"),
                  ),
                ),

                const Divider(thickness: 2),
              ],

              // ===========================
              // Minhas cartas
              // ===========================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  "Minhas cartas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: minhasCartas.length,
                itemBuilder: (context, index) {
                  final carta = minhasCartas[index];
                  final id = carta['id'];
                  final imagem = carta['imagem'] ?? 'assets/back_cards/0.png';
                  final nivel = carta['nivel'] ?? 0;
                  final pontos = carta['pontos_ganhos'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                      trailing: Checkbox(
                        value: _selecionadas.contains(id),
                        onChanged: (valor) {
                          setState(() {
                            if (valor == true) {
                              _selecionadas.add(id);
                            } else {
                              _selecionadas.remove(id);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (_selecionadas.contains(id)) {
                            _selecionadas.remove(id);
                          } else {
                            _selecionadas.add(id);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomSheet:
          _selecionadas.isNotEmpty
              ? Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mensagemController,
                        decoration: const InputDecoration(
                          hintText: "Digite uma mensagem",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final mensagem = _mensagemController.text.trim();
                        if (mensagem.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Digite uma mensagem antes de enviar.",
                              ),
                            ),
                          );
                          return;
                        }
                        if (_selecionadas.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selecione pelo menos uma carta."),
                            ),
                          );
                          return;
                        }

                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;

                        final cartasSnapshot =
                            await FirebaseFirestore.instance
                                .collection("usuarios")
                                .doc(uid)
                                .collection("inventario")
                                .doc("itens")
                                .collection("colecao")
                                .get();

                        final cartasSelecionadasData =
                            cartasSnapshot.docs
                                .where((doc) => _selecionadas.contains(doc.id))
                                .map((doc) {
                                  final data = doc.data();
                                  data['id'] = doc.id;
                                  return data;
                                })
                                .toList();

                        if (temProposta) {
                          await enviarContraProposta(
                            amigoUid: widget.amigoUid,
                            cartasSelecionadas: cartasSelecionadasData,
                            mensagem: mensagem,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Contra-proposta enviada!"),
                            ),
                          );
                        } else {
                          await salvarPropostaCompleta(
                            amigoUid: widget.amigoUid,
                            cartasSelecionadas: cartasSelecionadasData,
                            mensagem: mensagem,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Proposta enviada!")),
                          );
                        }

                        setState(() {
                          _selecionadas.clear();
                          _mensagemController.clear();
                        });
                      },
                      icon: const Icon(Icons.send),
                      label: Text(
                        temProposta ? "Enviar contraproposta" : "Enviar",
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
