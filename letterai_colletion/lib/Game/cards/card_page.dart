import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:letterai_colletion/Game/cards/support_cards.dart';

class CardPage extends StatefulWidget {
  final Map<String, dynamic> cardData;

  const CardPage({super.key, required this.cardData});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  late Map<String, dynamic> cardData;

  @override
  void initState() {
    super.initState();
    cardData = Map.from(widget.cardData);
  }

  @override
  Widget build(BuildContext context) {
    final statStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    // Chamada da função de apoio (fora da lista de widgets)
    final feedback = supportCards(cardData);

    Widget buildRow(String left, String right) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(left, style: statStyle, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 45),
          Expanded(
            child: Text(right, style: statStyle, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 25),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Conteúdo principal
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Imagem da carta
                  Center(
                    child: Image.asset(
                      cardData['imagem'] ?? 'assets/back_cards/0.png',
                      height: 480,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Barra de XP com texto sobre ela
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
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
                            '${cardData['nivel'] ?? 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Barra de XP com texto sobre ela
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Barra de progresso
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
                                    value:
                                        (cardData['xp'] ?? 0) /
                                        (50 + (50 * (cardData['nivel'] ?? 1))),
                                    backgroundColor: Colors.transparent,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.redAccent,
                                        ),
                                  ),
                                ),
                              ),
                              // Texto do XP
                              Text(
                                '${cardData['xp'] ?? 0} / ${50 + (50 * (cardData['nivel'] ?? 1))} XP',
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
                  const SizedBox(height: 24),

                  // Depois da barra de XP
                  if ((cardData['pontos_ganhos'] ?? 0) > 0) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              // Map para controlar os pontos atribuídos
                              Map<String, int> pontosDistribuidos = {
                                'Vida': 0,
                                'Ataque': 0,
                                'Defesa': 0,
                                'Velocidade': 0,
                                'Magia': 0,
                                'Sorte': 0,
                              };

                              int pontosDisponiveis =
                                  cardData['pontos_ganhos'] ?? 0;

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Text(
                                      'Pontos disponíveis: $pontosDisponiveis',
                                    ),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Gerando os campos de estatísticas
                                            ...pontosDistribuidos.keys.map((
                                              stat,
                                            ) {
                                              // Valor atual da estatística
                                              final valorAtual =
                                                  cardData[stat
                                                      .toLowerCase()] ??
                                                  0;

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4.0,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Nome + valor atual
                                                    Text(
                                                      '$stat: $valorAtual',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        // Botão de remover ponto
                                                        ElevatedButton(
                                                          onPressed:
                                                              pontosDistribuidos[stat]! >
                                                                      0
                                                                  ? () {
                                                                    setState(() {
                                                                      pontosDistribuidos[stat] =
                                                                          pontosDistribuidos[stat]! -
                                                                          1;
                                                                      pontosDisponiveis++;
                                                                    });
                                                                  }
                                                                  : null,
                                                          child: const Text(
                                                            '-',
                                                          ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                minimumSize:
                                                                    const Size(
                                                                      32,
                                                                      32,
                                                                    ),
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        // Botão de adicionar ponto
                                                        ElevatedButton(
                                                          onPressed:
                                                              pontosDisponiveis >
                                                                      0
                                                                  ? () {
                                                                    setState(() {
                                                                      pontosDistribuidos[stat] =
                                                                          pontosDistribuidos[stat]! +
                                                                          1;
                                                                      pontosDisponiveis--;
                                                                    });
                                                                  }
                                                                  : null,
                                                          child: const Text(
                                                            '+',
                                                          ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                minimumSize:
                                                                    const Size(
                                                                      32,
                                                                      32,
                                                                    ),
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        // Número de pontos atribuídos
                                                        Text(
                                                          '${pontosDistribuidos[stat]}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),

                                            const SizedBox(height: 16),
                                            const Text(
                                              'Volte para a coleção e entre novamente para atualizar a carta',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          await aplicarPontos(
                                            pontosDistribuidos,
                                            cardData['id'],
                                          );
                                          Navigator.of(context).pop();
                                          setState(
                                            () {},
                                          ); // Atualiza a tela da carta
                                        },
                                        child: const Text('Salvar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Você tem pontos não usados!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Estatísticas em card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            buildRow(
                              "Vida: ${cardData['vida'] ?? 0}",
                              "Ataque: ${cardData['ataque'] ?? 0}",
                            ),
                            const SizedBox(height: 12),
                            buildRow(
                              "Defesa: ${cardData['defesa'] ?? 0}",
                              "Velocidade: ${cardData['velocidade'] ?? 0}",
                            ),
                            const SizedBox(height: 12),
                            buildRow(
                              "Magia: ${cardData['magia'] ?? 0}",
                              "Sorte: ${cardData['sorte'] ?? 0}",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(thickness: 2),

                  // Lógica de evoluir (apenas se o feedback não estiver vazio)
                  if (feedback.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Image.asset(
                                    getEnergyImage(cardData['tipo1']),
                                    width: 100,
                                    height: 150,
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<int>(
                                    future: getInventoryEnergy(
                                      cardData['tipo1'],
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return const Text("Erro");
                                      }
                                      return Text(
                                        "x${snapshot.data ?? 0}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(width: 16),
                              const Icon(
                                Icons.arrow_forward,
                                size: 40,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 16),
                              Image.asset(
                                getEvoImage(cardData['evolui']),
                                width: 100,
                                height: 150,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          FutureBuilder<int>(
                            future: getInventoryEnergy(cardData['tipo1']),
                            builder: (context, snapshot) {
                              final userEnergy = snapshot.data ?? 0;
                              final energyRequired = 5;
                              final canEvolve = userEnergy >= energyRequired;

                              return ElevatedButton(
                                onPressed:
                                    canEvolve
                                        ? () async {
                                          await evolveCard(
                                            cardData,
                                            energyRequired: energyRequired,
                                          );
                                          setState(() {});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Carta evoluída com sucesso!",
                                              ),
                                            ),
                                          );
                                        }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      canEvolve ? Colors.green : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Evoluir",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 2),
                    const SizedBox(height: 16),
                  ],

                  // Botão de selecionar carta
                  ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      try {
                        // Salva a carta ativa
                        await FirebaseFirestore.instance
                            .collection("usuarios")
                            .doc(user.uid)
                            .collection("inventario")
                            .doc("itens")
                            .collection("carta_ativa")
                            .doc("selecionada")
                            .set(cardData);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Carta selecionada com sucesso!"),
                          ),
                        );

                        Navigator.pop(context); // Fecha a página da carta
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erro ao selecionar carta: $e"),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Selecionar Carta",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botão de fechar
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
