import 'dart:async';
//import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:letterai_colletion/Health/graphics/visual/exercise_graphic.dart';
import 'package:letterai_colletion/Health/graphics/visual/progress_bars.dart';
import 'package:letterai_colletion/Health/graphics/visual/sleep_graphic.dart';
import 'package:letterai_colletion/Health/graphics/visual/metrics_graphic.dart';
//import 'package:letterai_colletion/Health/support/util.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';

//import 'package:letterai_colletion/Health/diary_sync/dados_fixos.dart';
//import 'package:letterai_colletion/Health/diary_sync/dados_continuos.dart';

import 'package:letterai_colletion/Health/permanent_sync/dados_fixos_perm.dart';
import 'package:letterai_colletion/Health/permanent_sync/dados_continuos_perm.dart';

import 'package:letterai_colletion/Health/graphics/metrics_page.dart';
import 'package:letterai_colletion/Health/graphics/sleep_page.dart';

//import 'package:letterai_colletion/Game/score.dart';
import 'package:letterai_colletion/Database_Support/sync_functions.dart';
import 'package:letterai_colletion/Health/graphics/return_daily_goal.dart';
import 'package:letterai_colletion/Database_Support/exercise_data.dart';

const String syncTaskName = "sync_dados_permanentes";
final health = Health();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == syncTaskName) {
      await sincronizarDadosFixosPermantentes();
      await sincronizarDadosContinuosPermanentes();
    }
    return Future.value(true);
  });
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  HealthPageState createState() => HealthPageState();
}

class HealthPageState extends State<HealthPage> {
  Future<MetasUsuario>? _metasFuture;
  
  @override
  void initState() {
    // configure the health plugin before use and check the Health Connect status
    health.configure();
    health.getHealthConnectSdkStatus();

    super.initState();

    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

    _registrarAgendamento();

    _metasFuture = buscarMetasUsuario(
      FirebaseAuth.instance.currentUser!.uid,
    );
  }

  Future<void> _registrarAgendamento() async {
    final now = DateTime.now();

    final proximaExecucao = DateTime(
      now.year,
      now.month,
      now.day,
      0,
      5,
    ).add(const Duration(days: 1));

    final delay = proximaExecucao.difference(now);

    await Workmanager().registerPeriodicTask(
      "sync-task-id",
      syncTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Saúde')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            const SizedBox(height: 8),
            Divider(thickness: 1),
            const SizedBox(height: 7),
            Text(
              'Seu progresso de hoje',
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            //Barras de progresso
            Consumer<dadosDiariosProvider>(
              builder: (context, dados, child) {
                return FutureBuilder<MetasUsuario>(
                  future: buscarMetasUsuario(
                    FirebaseAuth.instance.currentUser!.uid,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final metas = snapshot.data!;

                    return Column(
                      children: [
                        ProgressBars(
                          imagem: 'assets/sprites_sistema/steps.png',
                          valorAtual: dados.totalPassos,
                          meta: metas.passos,
                          corBarra: const Color(0xFF7FFF00),
                        ),
                        const SizedBox(height: 20),

                        ProgressBars(
                          imagem: 'assets/sprites_sistema/distance.png',
                          valorAtual:
                              dados.totalDistancia
                                  .toInt(), // cuidado com double
                          meta: metas.distancia.toInt(),
                          corBarra: const Color(0xFF4169E1),
                        ),
                        const SizedBox(height: 20),

                        ProgressBars(
                          imagem: 'assets/sprites_sistema/calories.png',
                          valorAtual: dados.totalCalorias,
                          meta: metas.calorias,
                          corBarra: const Color(0xFFFFA500),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            SizedBox(height: 5),
            Divider(thickness: 1),
            SizedBox(height: 5),
            Text(
              'Dados diários',
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Sessão de sono',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            //Adicionar gráfico de sono
            SleepGraphic(
              metasFuture: buscarMetasUsuario(
                FirebaseAuth.instance.currentUser!.uid,
              ),
            ),

            SizedBox(height: 10),
            Divider(thickness: 1),
            const SizedBox(height: 10),
            Text(
              'Atividades fisicas',
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            //Gráfico dos exercícios
            Consumer<dadosDiariosProvider>(
              builder: (context, dados, child) {
                // Se não houver dados de exercício, podemos mostrar uma mensagem ou um widget vazio.
                if (dados.sessoesExercicio.isEmpty) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text("Nenhum exercício registrado hoje."),
                    ),
                  );
                }
                debugPrint('_metasFuture: $_metasFuture');


                try {
                  final List<ExercicioSessao> sessoesFormatadas = [];
                  final now = DateTime.now();

                  for (int i = 0; i < dados.sessoesExercicio.length; i += 3) {

                    if (i + 2 >= dados.sessoesExercicio.length) break;

                    if (dados.sessoesExercicio[i + 1] == null || dados.sessoesExercicio[i + 2] == null) {
                      debugPrint('não é nulo');
                      continue;
                    } else {
                      debugPrint('${dados.sessoesExercicio}');
                    }

                    final int inicioInt = dados.sessoesExercicio[i + 1];
                    final int fimInt = dados.sessoesExercicio[i + 2];
                    final int atividade = dados.sessoesExercicio[i + 0];
                    debugPrint('${dados.passosHora} =============');

                    final int horaInicio = inicioInt ~/ 100;
                    final int minutoInicio = inicioInt % 100;
                    final int horaFim = fimInt ~/ 100;
                    final int minutoFim = fimInt % 100;

                    DateTime inicioDT = DateTime(now.year, now.month, now.day, horaInicio, minutoInicio);
                    DateTime fimDT = DateTime(now.year, now.month, now.day, horaFim, minutoFim);

                    if (fimDT.isBefore(inicioDT)) {
                      fimDT = fimDT.add(const Duration(days: 1));
                    }

                    sessoesFormatadas.add(
                      ExercicioSessao(inicio: inicioDT, fim: fimDT, atividade: atividade)
                    );
                  }

                  return ExerciseGraphic(sessoes: sessoesFormatadas);
                  
                } catch (e) {
                  // Se a conversão falhar, mostramos uma mensagem de erro.
                  print("Erro ao converter dados de exercício: $e");
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text("Erro ao exibir dados de exercício."),
                    ),
                  );
                }
              },
            ),

            SizedBox(height: 10),
            Divider(thickness: 1),
            const SizedBox(height: 10),
            Text(
              'Métricas diárias',
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            

            //Gráfico de passos
            Consumer<dadosDiariosProvider>(
              builder: (context, dados, child) {
                if (dados.passosHora.isEmpty) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: Text("Nenhum dado de passos disponível.")),
                  );
                }
                
                debugPrint('<><><${dados.passosHora}');

                return BarChartGeneric(
                  valores: dados.passosHora, // já contém 24 posições, 1 por hora
                  titulo: 'Passos por hora',
                  corBarra: const Color(0xFF7FFF00),
                  tipoMetrica: 0,
                  total : dados.totalPassos,
                );
              },
            ),
            const SizedBox(height: 20),

            //Gráfico de distancia
            Consumer<dadosDiariosProvider>(
              builder: (context, dados, child) {
                if (dados.distanciaHora.isEmpty) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: Text("Nenhum dado de passos disponível.")),
                  );
                }

                return BarChartGeneric(
                  valores: dados.distanciaHora, // já contém 24 posições, 1 por hora
                  titulo: 'Distância percorrida por hora',
                  corBarra: const Color(0xFF4169E1),
                  tipoMetrica: 1,
                  total : dados.totalDistancia,
                );
              },
            ),
            const SizedBox(height: 20),

            //Gráfico de calorias
            Consumer<dadosDiariosProvider>(
              builder: (context, dados, child) {
                if (dados.caloriasHora.isEmpty) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: Text("Nenhum dado de passos disponível.")),
                  );
                }

                return BarChartGeneric(
                  valores: dados.caloriasHora, // já contém 24 posições, 1 por hora
                  titulo: 'Calorias queimadas por hora',
                  corBarra: const Color(0xFFFFA500),
                  tipoMetrica: 2,
                  total : dados.totalCalorias,
                );
              },
            ),
            //Tudo o que fica na tela deve ficar acima desse colchete e desse parentese
          ],
        ),
        // Botões do rodapé
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MetricsPage()),
                    );
                  },
                  child: const Text('Ver Métricas'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SleepPage()),
                    );
                  },
                  child: const Text('Sono'),
                ),
              ),
            ],
          ),
        ),

        // Popup menu button
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Builder(
            builder:
                (context) => FloatingActionButton(
                  child: const Icon(Icons.menu),
                  onPressed: () async {
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final overlay =
                        Overlay.of(context).context.findRenderObject()
                            as RenderBox;

                    final Offset buttonTopLeft = button.localToGlobal(
                      Offset.zero,
                      ancestor: overlay,
                    );

                    final Offset buttonBottomRight = button.localToGlobal(
                      button.size.bottomRight(Offset.zero),
                      ancestor: overlay,
                    );

                    const double verticalOffset = 165.0;

                    final result = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        Rect.fromPoints(
                          buttonTopLeft.translate(0, -verticalOffset),
                          buttonBottomRight.translate(0, -verticalOffset),
                        ),
                        Offset.zero & overlay.size,
                      ),
                      items: [
                        const PopupMenuItem(
                          value: 'health',
                          child: Text('Health'),
                        ),
                        const PopupMenuItem(
                          value: 'sync',
                          child: Text('Sincronizar'),
                        ),
                        const PopupMenuItem(
                          value: 'sync_pem',
                          child: Text('SincronizarPerm'),
                        ),
                      ],
                    );

                    if (result == 'health') {
                      installHealthConnect();
                    } else if (result == 'sync') {
                      await sincronizarTudo(
                        sync: (valor) {
                          setState(() => sync = valor);
                        },
                      );
                    } else if (result == 'sync_pem') {
                      await sincronizarTudoPerm(
                        sync: (valor) {
                          setState(() => sync = valor);
                        },
                      );
                    }
                  },
                ),
          ),
        ),
      ),
    );
  }
}
