import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letterai_colletion/Menu/home_page.dart';

class CustomProfilePage extends StatefulWidget {
  const CustomProfilePage({super.key});

  @override
  State<CustomProfilePage> createState() => _CustomProfilePageState();
}

class _CustomProfilePageState extends State<CustomProfilePage> {
  final _apelidoController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  List<String> _avatars = [];
  String? _selectedAvatar;

  List<Map<String, dynamic>> _personagens = [];
  String? _selectedPersonagem;

  @override
  void initState() {
    super.initState();
    _carregarAvatares();
    _carregarPersonagens();
    _carregarDadosExistentes();
  }

  /// 🔹 Busca todos os avatares
  Future<void> _carregarAvatares() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("avatar").get();

    setState(() {
      _avatars = snapshot.docs.map((doc) => doc['imagem'] as String).toList();
    });
  }

  /// 🔹 Busca todos os personagens
  Future<void> _carregarPersonagens() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("personagem").get();

    setState(() {
      _personagens =
          snapshot.docs
              .map((doc) => {"id": doc['id'], "imagem": doc['imagem']})
              .toList();
    });
  }

  /// 🔹 Carrega dados já salvos em "dados_pessoais"
  Future<void> _carregarDadosExistentes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid)
        .collection("estatisticas")
        .doc("dados_pessoais");

    final snap = await docRef.get();

    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        _apelidoController.text = data["apelido"] ?? "";
        _selectedAvatar = data["avatar"];
        _selectedPersonagem = data["personagem"];
      });
    }
  }

  /// 🔹 Salva apelido, avatar e personagem
  Future<void> _salvarDados() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final apelido = _apelidoController.text.trim();
    if (apelido.isEmpty ||
        _selectedAvatar == null ||
        _selectedPersonagem == null)
      return;

    final docRef = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid)
        .collection("estatisticas")
        .doc("dados_pessoais");

    await docRef.set({
      "apelido": apelido,
      "avatar": _selectedAvatar,
      "personagem": _selectedPersonagem,
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Primeiro Acesso")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Escolha seu apelido, avatar e personagem:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _apelidoController,
              decoration: const InputDecoration(
                labelText: "Apelido",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Selecione seu avatar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 12),

            // 🔹 Avatares
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatarPath = _avatars[index];
                  final isSelected = _selectedAvatar == avatarPath;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatarPath;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.lightGreenAccent
                                  : Colors.grey,
                          width: isSelected ? 5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(avatarPath, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),

            const Text(
              "Selecione seu personagem",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),

            // 🔹 Personagens
            if (_personagens.isNotEmpty)
              SizedBox(
                height: 160,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _personagens.length,
                  itemBuilder: (context, index) {
                    final personagem = _personagens[index];
                    final isSelected =
                        _selectedPersonagem == personagem["imagem"];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPersonagem = personagem["imagem"];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.lightGreenAccent
                                    : Colors.grey,
                            width: isSelected ? 5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            personagem["imagem"].toString().startsWith(
                                  "assets/",
                                )
                                ? Image.asset(
                                  personagem["imagem"],
                                  fit: BoxFit.contain,
                                )
                                : Image.network(
                                  personagem["imagem"],
                                  fit: BoxFit.contain,
                                ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _salvarDados,
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
