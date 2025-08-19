import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;
import 'package:intl/intl.dart';

import 'package:letterai_colletion/Health/graphics/data/diary_data.dart';
import 'package:letterai_colletion/Health/graphics/data/perm_data.dart';
import 'package:letterai_colletion/Health/support/acitivities.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  String tipoSelecionado = 'STEPS';
  bool modoDiario = true;
  bool mostrarCalendario = false;
  late Future<List<int>> dadosFuturo;
  String? userId;
  late final Map<int, String> mapaAtividades;

  DateTime _selectedDay = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      dadosFuturo = _buscarDadosSelecionados();
    }
    mapaAtividades = gerarNomeAtividades();
  }

  Future<List<int>> _buscarDadosSelecionados({DateTime? dia}) {
    if (userId == null) return Future.value([]);

    final dataFiltrada = dia ?? _selectedDay;

    if (modoDiario) {
      switch (tipoSelecionado) {
        case 'STEPS':
          return buscarPassosDiarios(userId!);
        case 'TOTAL_CALORIES_BURNED':
          return buscarCaloriasDiarias(userId!);
        case 'DISTANCE_DELTA':
          return buscarDistanciaDiaria(userId!);
        case 'WORKOUTS':
          return buscarExercicioDiario(userId!);
        default:
          return Future.value([]);
      }
    } else {
      switch (tipoSelecionado) {
        case 'STEPS':
          return buscarPassosPermanentes(userId!, dia: dataFiltrada);
        case 'TOTAL_CALORIES_BURNED':
          return buscarCaloriasPermanentes(userId!, dia: dataFiltrada);
        case 'DISTANCE_DELTA':
          return buscarDistanciaPermanente(userId!, dia: dataFiltrada);
        case 'WORKOUTS':
          return buscarExercicioPermanente(userId!, dia: dataFiltrada);
        default:
          return Future.value([]);
      }
    }
  }

  final Map<String, String> nomesMetricas = {
    'STEPS': 'Passos',
    'TOTAL_CALORIES_BURNED': 'Calorias',
    'DISTANCE_DELTA': 'Distância',
    'WORKOUTS': 'Exercícios',
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

    //String dataFormatada = DateFormat('dd-MM-yyyy').format(_selectedDay);

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
                DropdownMenuItem(value: 'WORKOUTS', child: Text('Exercícios')),
              ],
              onChanged: (value) {
                if (value != null) atualizarTipo(value);
              },
            ),
          ),
          if (!modoDiario)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _selectedDay = _selectedDay.subtract(
                              const Duration(days: 1),
                            );
                            dadosFuturo = _buscarDadosSelecionados(
                              dia: _selectedDay,
                            );
                          });
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                mostrarCalendario = !mostrarCalendario;
                                dadosFuturo = _buscarDadosSelecionados(
                                  dia: _selectedDay,
                                );
                              });
                            },
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(_selectedDay),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          setState(() {
                            _selectedDay = _selectedDay.add(
                              const Duration(days: 1),
                            );
                            dadosFuturo = _buscarDadosSelecionados(
                              dia: _selectedDay,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  if (mostrarCalendario)
                    CalendarCarousel<Event>(
                      selectedDateTime: _selectedDay,
                      onDayPressed: (date, events) {
                        setState(() {
                          _selectedDay = date;
                          mostrarCalendario = false;
                          dadosFuturo = _buscarDadosSelecionados(
                            dia: _selectedDay,
                          );
                        });
                      },
                      weekendTextStyle: const TextStyle(color: Colors.red),
                      thisMonthDayBorderColor: Colors.grey,
                      weekFormat: false,
                      height: 380.0,
                      selectedDayBorderColor: Colors.blue,
                      selectedDayButtonColor: Colors.blueAccent,
                    ),
                ],
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
                            : tipoSelecionado == 'DISTANCE_DELTA'
                            ? 'Distância total: $total'
                            : '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount:
                              tipoSelecionado != 'WORKOUTS'
                                  ? valoresPorHora.length
                                  : valoresPorHora.length ~/ 3,
                          itemBuilder: (context, i) {
                            if (tipoSelecionado != 'WORKOUTS') {
                              return ListTile(
                                title: Text('${i.toString().padLeft(2, '0')}h'),
                                trailing: Text(
                                  tipoSelecionado == 'STEPS'
                                      ? '${valoresPorHora[i]} passos'
                                      : tipoSelecionado ==
                                          'TOTAL_CALORIES_BURNED'
                                      ? '${valoresPorHora[i]} kcal'
                                      : '${valoresPorHora[i]} m',
                                ),
                              );
                            } else {
                              final atividade = valoresPorHora[i * 3];
                              final inicio = valoresPorHora[i * 3 + 1];
                              final fim = valoresPorHora[i * 3 + 2];

                              String formatarHora(int hhmm) {
                                final h = hhmm ~/ 100;
                                final m = hhmm % 100;
                                return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                              }

                              final nomeAtividade = mapaAtividades[atividade] ?? 'Exercício desconhecido';

                              return ListTile(
                                title: Text(nomeAtividade),
                                subtitle: Text(
                                  'Início: ${formatarHora(inicio)}, Fim: ${formatarHora(fim)}',
                                ),
                              );
                            }
                          },
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
