import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:letterai_colletion/Health/graphics/data/diary_data.dart';

import 'package:letterai_colletion/Health/graphics/data/perm_data.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  String tipoSelecionado = 'STEPS';
  bool modoDiario = true;
  late Future<List<int>> dadosFuturo;
  String? userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      dadosFuturo = _buscarDadosSelecionados();
    }
  }

  Future<List<int>> _buscarDadosSelecionados() {
    if (userId == null) return Future.value([]);

    if (modoDiario) {
      switch (tipoSelecionado) {
        case 'STEPS':
          return buscarPassosPermanentes(userId!);
        case 'TOTAL_CALORIES_BURNED':
          return buscarCaloriasDiarias(userId!);
        case 'DISTANCE_DELTA':
          return buscarDistanciaDiaria(userId!);
        default:
          return Future.value([]);
      }
    } else {
      switch (tipoSelecionado) {
        case 'STEPS':
          return buscarPassosPermanentes(userId!);
        case 'TOTAL_CALORIES_BURNED':
          return buscarCaloriasPermanentes(userId!);
        case 'DISTANCE_DELTA':
          return buscarDistanciaPermanente(userId!);
        default:
          return Future.value([]);
      }
    }
  }

  final Map<String, String> nomesMetricas = {
    'STEPS': 'Passos',
    'TOTAL_CALORIES_BURNED': 'Calorias',
    'DISTANCE_DELTA': 'Distância',
  };

  void atualizarTipo(String novoTipo) {
    setState(() {
      tipoSelecionado = novoTipo;
      dadosFuturo = _buscarDadosSelecionados();
    });
  }

  void atualizarModo(bool diario) {
    setState(() {
      modoDiario = diario;
      dadosFuturo = _buscarDadosSelecionados();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Você precisa estar logado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Suas métricas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => atualizarModo(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: modoDiario ? Colors.green : Colors.grey,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Diários",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => atualizarModo(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !modoDiario ? Colors.green : Colors.grey,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Histórico",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: tipoSelecionado,
              items: const [
                DropdownMenuItem(value: 'STEPS', child: Text('Passos')),
                DropdownMenuItem(
                  value: 'TOTAL_CALORIES_BURNED',
                  child: Text('Calorias'),
                ),
                DropdownMenuItem(
                  value: 'DISTANCE_DELTA',
                  child: Text('Distância'),
                ),
              ],
              onChanged: (value) {
                if (value != null) atualizarTipo(value);
              },
            ),
          ),

          Expanded(
            child: FutureBuilder<List<int>>(
              future: dadosFuturo,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum dado encontrado'));
                }

                final valoresPorHora = snapshot.data!;
                final total = valoresPorHora.fold(0, (sum, val) => sum + val);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        tipoSelecionado == 'STEPS'
                            ? 'Passos total: $total'
                            : tipoSelecionado == 'TOTAL_CALORIES_BURNED'
                            ? 'Calorias total: $total'
                            : 'Distância total: $total',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: List.generate(valoresPorHora.length, (i) {
                            return ListTile(
                              title: Text('${i.toString().padLeft(2, '0')}h'),
                              trailing: Text(
                                '${valoresPorHora[i]} ${tipoSelecionado == 'STEPS'
                                    ? 'passos'
                                    : tipoSelecionado == 'TOTAL_CALORIES_BURNED'
                                    ? 'kcal'
                                    : 'm'}',
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
