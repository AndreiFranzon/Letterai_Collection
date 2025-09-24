import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:letterai_colletion/Database_Support/pontos_provider.dart';
import 'package:letterai_colletion/Friends/friends_page.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
//import 'package:letterai_colletion/Login/login_page.dart';
import 'package:letterai_colletion/Login/auth_service.dart';
import 'package:letterai_colletion/Profile/daily_goal.dart';
import 'package:letterai_colletion/Profile/inventory.dart';
import 'package:provider/provider.dart';
import 'package:gif/gif.dart';
import 'package:letterai_colletion/Profile/custom_profile.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gif/gif.dart';

class UserData {
  final Map<String, dynamic> dadosPessoais;
  final int nivel;
  final int cartasObtidas;

  UserData({
    required this.dadosPessoais,
    required this.nivel,
    required this.cartasObtidas,
  });
}

// Função para carregar dados do usuário
Future<UserData> carregarDadosUsuario() async {
  final db = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    // Usuário não está logado, lançamos exceção ou retornamos defaults
    throw Exception("Usuário não está logado");
  }

  final uid = currentUser.uid;

  // Buscar dados pessoais
  final dadosPessoaisSnap =
      await db
          .collection("usuarios")
          .doc(uid)
          .collection("estatisticas")
          .doc("dados_pessoais")
          .get();

  // Buscar nível
  final nivelSnap =
      await db
          .collection("usuarios")
          .doc(uid)
          .collection("estatisticas")
          .doc("nivel")
          .get();

  // Buscar cartas obtidas
  final cartasSnap =
      await db
          .collection("usuarios")
          .doc(uid)
          .collection("inventario")
          .doc("itens")
          .collection("cartas_obtidas")
          .doc("lista")
          .get();

  final cartasData = cartasSnap.data();
  final cartasObtidas = (cartasData?["cartas_obtidas"] as List<dynamic>? ?? [])
    .map((carta) => carta.toString())
    .toList();

  return UserData(
    dadosPessoais: dadosPessoaisSnap.data() ?? {},
    nivel: nivelSnap.data()?["valor"] ?? 1,
    cartasObtidas: cartasObtidas.length,
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late GifController _gifController;

  @override
  void initState() {
    super.initState();
    _gifController = GifController(vsync: this);
    _gifController.value = 0; // Começa no primeiro frame
  }

  @override
  void dispose() {
    _gifController.dispose();
    super.dispose();
  }

  void _abrirInventario() async {
    // Anima do primeiro ao último frame
    await _gifController.animateTo(
      16, // substitua pelo número de frames do seu GIF
      duration: const Duration(seconds: 1),
    );

    // Abre a tela de inventário
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryPage(),
        fullscreenDialog: true,
      ),
    );

    // Ao voltar, retorna ao primeiro frame
    _gifController.value = 0;
  }

  @override
Widget build(BuildContext context) {
  final pontosProvider = Provider.of<PontosProvider>(context);

  return FutureBuilder<UserData>(
    future: carregarDadosUsuario(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(body: Center(child: Text("Erro: ${snapshot.error}")));
      }
      if (!snapshot.hasData) {
        return const Scaffold(
          body: Center(child: Text("Nenhum dado encontrado")),
        );
      }

      final user = snapshot.data!;

      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          title: pontosProvider.carregando
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  children: [
                    // Círculo do nível
                    Container(
                      width: 50,
                      height: 50,
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
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Barra de XP
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pontosProvider.xp /
                                    (50 + (50 * pontosProvider.nivel)),
                                backgroundColor: Colors.transparent,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${pontosProvider.xp} / ${50 + (50 * pontosProvider.nivel)} XP',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        body: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão de Metas
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyGoalPage(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/sprites_sistema/target.png',
                      width: 180,
                      height: 180,
                    ),
                  ),
                  const SizedBox(width: 0),

                  // Botão "Editar perfil"
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomProfilePage(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Editar perfil",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.black, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),
                  // Botão de Inventário
                  GestureDetector(
                    onTap: _abrirInventario,
                    child: Gif(
                      controller: _gifController,
                      image: const AssetImage(
                        'assets/sprites_sistema/inventory_bag.gif',
                      ),
                      width: 120,
                      height: 120,
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 80),

                      // Retângulo com avatar e apelido
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: AssetImage(
                                    user.dadosPessoais["avatar"],
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 100),

                            // Apelido
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  user.dadosPessoais["apelido"] ?? "Jogador",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔥 NOVO BLOCO COM AS DUAS COLUNAS
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 12),
                                  Image.asset(
                                    user.dadosPessoais["personagem"],
                                    height: 300,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  
                                  
                                  Text(
                                    "Cartas obtidas:${user.cartasObtidas}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
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

                  // Botão de amigos no topo
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendsPage(),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/sprites_sistema/friend.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
    }
