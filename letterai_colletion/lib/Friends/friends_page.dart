import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:letterai_colletion/Friends/friends_support.dart';
import 'package:letterai_colletion/Friends/replace_cards/confirm_page.dart';
import 'package:letterai_colletion/Friends/replace_cards/replace_cards.dart';
import 'package:letterai_colletion/Login/login_support.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _buscarController = TextEditingController();
  bool carregando = true;
  String myFriendCode = "";
  Map<String, dynamic>? resultadoBusca;

  @override
  void initState() {
    super.initState();
    _carregarFriendCode();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _carregarFriendCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final code = await FriendsSupport.carregarFriendCode(user.uid);
    setState(() {
      myFriendCode = code;
      carregando = false;
    });
  }

  Future<void> _mostrarPedidos(BuildContext parentContext) async {
    final meuUid = FirebaseAuth.instance.currentUser?.uid;
    if (meuUid == null) return;

    final pedidos = await FriendsSupport.buscarPedidosRecebidos(meuUid);

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Pedidos de amizade"),
          content: SizedBox(
            width: double.maxFinite,
            child:
                pedidos.isEmpty
                    ? const Text("Nenhum pedido recebido")
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: pedidos.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidos[index];
                        final uuid = pedido['uuid'] as String;

                        // FutureBuilder para carregar os dados do remetente
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: FriendsSupport.dadosAmigo(uuid),
                          builder: (context, snapshotAmigo) {
                            if (!snapshotAmigo.hasData) {
                              return const ListTile(
                                title: Text("Carregando..."),
                              );
                            }

                            final dadosAmigo = snapshotAmigo.data!;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage(
                                  dadosAmigo['avatar'],
                                ),
                              ),
                              title: Text(dadosAmigo['apelido']),
                              subtitle: Text("Nível: ${dadosAmigo['nivel']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      if (meuUid != null) {
                                        await FriendsSupport.aceitarPedido(
                                          meuUid,
                                          uuid,
                                        );
                                        Navigator.of(dialogContext).pop();
                                        ScaffoldMessenger.of(
                                          parentContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Amizade aceita com ${dadosAmigo['apelido']}",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await FriendsSupport.recusarPedido(
                                        meuUid,
                                        uuid,
                                      );
                                      Navigator.of(dialogContext).pop();
                                      ScaffoldMessenger.of(
                                        parentContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Amizade recusada com ${dadosAmigo['apelido']}",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Amigos")),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Mostra friend code próprio
          if (carregando)
            const CircularProgressIndicator()
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    myFriendCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: myFriendCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Código copiado!")),
                      );
                    },
                    child: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Campo para buscar amigo
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscarController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Código do amigo",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final code = _buscarController.text.trim();
                  if (code.isEmpty) return;

                  final resultado = await FriendsSupport.buscarFriendCode(code);
                  if (resultado != null) {
                    setState(() => resultadoBusca = resultado);
                  } else {
                    setState(() => resultadoBusca = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Usuário não encontrado")),
                    );
                  }
                },
                child: const Text("Buscar"),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Resultado da pesquisa
          if (resultadoBusca != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(resultadoBusca!['avatar']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resultadoBusca!['apelido'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Nível: ${resultadoBusca!['nivel']}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final meuUid = FirebaseAuth.instance.currentUser?.uid;
                      final friendUid = resultadoBusca!['uid'];

                      if (meuUid != null && friendUid != null) {
                        await FriendsSupport.enviarPedidoAmizade(
                          meuUid,
                          friendUid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Pedido de amizade enviado!"),
                          ),
                        );
                        setState(() {
                          resultadoBusca = null;
                          _buscarController.clear();
                        });
                      }
                    },
                    child: const Text("Adicionar"),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          const Divider(thickness: 2),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Meus Amigos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Lista de amigos
          // Lista de amigos
Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('usuarios')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('aceitas')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text("Nenhum amigo encontrado."),
        );
      }

      final amigosDocs = snapshot.data!.docs;

      return ListView.builder(
        itemCount: amigosDocs.length,
        itemBuilder: (context, index) {
          final amigoUid = amigosDocs[index].id;

          return FutureBuilder<Map<String, dynamic>?>(
            future: FriendsSupport.dadosAmigo(amigoUid),
            builder: (context, snapshotAmigo) {
              if (!snapshotAmigo.hasData) {
                return const ListTile(title: Text("Carregando..."));
              }

              final dadosAmigo = snapshotAmigo.data!;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(dadosAmigo['avatar']),
                ),
                title: Text(dadosAmigo['apelido']),
                subtitle: Text("Nível: ${dadosAmigo['nivel']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stream para proposta recebida
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("usuarios")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection("estatisticas")
                          .doc("propostas")
                          .collection("recebidas")
                          .doc(amigoUid)
                          .snapshots(),
                      builder: (context, snapshotProposta) {
                        final existeProposta = snapshotProposta.hasData && snapshotProposta.data!.exists;

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("usuarios")
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection("estatisticas")
                              .doc("propostas")
                              .collection("contraproposta_recebida")
                              .doc(amigoUid)
                              .snapshots(),
                          builder: (context, snapshotContra) {
                            final existeContra = snapshotContra.hasData && snapshotContra.data!.exists;

                            // Decide qual ícone mostrar
                            if (existeContra) {
                              return const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              );
                            } else if (existeProposta) {
                              return const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                ),
                              );
                            } else {
                              return const SizedBox(width: 0);
                            }
                          },
                        );
                      },
                    ),

                    // 📤 Botão enviar proposta ou ConfirmPage
                    IconButton(
                      tooltip: "Enviar proposta de troca",
                      iconSize: 40,
                      icon: Image.asset("assets/back_cards/0.png"),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection("usuarios")
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection("estatisticas")
                            .doc("propostas")
                            .collection("contraproposta_recebida")
                            .doc(amigoUid)
                            .get()
                            .then((doc) {
                          if (doc.exists) {
                            // Existe contraproposta -> vai para ConfirmPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConfirmPage(amigoUid: amigoUid),
                              ),
                            );
                          } else {
                            // Não existe contraproposta -> abrir ReplaceCardsPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReplaceCardsPage(amigoUid: amigoUid),
                              ),
                            );
                          }
                        });
                      },
                    ),

                    const SizedBox(width: 8),

                    // 🗑️ Botão remover amigo
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Confirmar remoção"),
                              content: Text(
                                "Você realmente quer remover ${dadosAmigo['apelido']} da sua lista de amigos?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Não"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final meuUid = FirebaseAuth.instance.currentUser?.uid;
                                    if (meuUid != null) {
                                      await FriendsSupport.removerAmigo(meuUid, amigoUid);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("${dadosAmigo['apelido']} removido da sua lista"),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    "Sim",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  ),
),

        ],
      ),
    ),

    floatingActionButton: FloatingActionButton(
      onPressed: () => _mostrarPedidos(context),
      child: const Icon(Icons.group),
    ),
  );
}

}
