import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:letterai_colletion/Health/graphics/metrics_page.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:letterai_colletion/Health/graphics/return_daily_goal.dart';
import 'package:letterai_colletion/Database_Support/exercise_data.dart';
import 'package:letterai_colletion/Health/graphics/sleep_page.dart';
import 'package:letterai_colletion/Database_Support/exercise_data.dart';
import 'package:letterai_colletion/Health/support/acitivities.dart';

class ExercicioSessao {
  final DateTime inicio;
  final DateTime fim;
  final int atividade;

  ExercicioSessao({
    required this.inicio,
    required this.fim,
    required this.atividade,
  });
}

class ExerciseGraphic extends StatelessWidget {
  final List<ExercicioSessao> sessoes;

  const ExerciseGraphic({super.key, required this.sessoes});

  // Função para converter DateTime em um valor numérico para o eixo X
  double _dateTimeToHours(DateTime dt, DateTime diaBase) {
    return dt.difference(diaBase).inMinutes / 60.0;
  }

  // Função para pegar metas (como no seu código original)
  Future<MetasUsuario> _pegarMetas() async {
    return await buscarMetasUsuario(FirebaseAuth.instance.currentUser!.uid);
  }

  // Dica extra: Função para dar cores diferentes por tipo de atividade
  Color _getCorPorAtividade(int atividade) {
    // Você pode criar uma lógica mais elaborada aqui
    // Ex: if (atividade == 40) return Colors.runColor;
    final cores = [
      Colors.orangeAccent,
      Colors.lightBlueAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
    ];
    return cores[atividade % cores.length];
  }

  @override
  Widget build(BuildContext context) {
    if (sessoes.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Nenhum exercício registrado hoje.")),
      );
    }

    final sessoesOrdenadas = List<ExercicioSessao>.from(sessoes)
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

    // Definir início e fim do eixo
    final primeiroInicio = sessoesOrdenadas.first.inicio;
    DateTime ultimoFim = sessoesOrdenadas.first.fim;
    for (var sessao in sessoesOrdenadas) {
      if (sessao.fim.isAfter(ultimoFim)) ultimoFim = sessao.fim;
    }

    final diaBase = DateTime(
      primeiroInicio.year,
      primeiroInicio.month,
      primeiroInicio.day,
    );

    final double minHoraEixo = _dateTimeToHours(
      primeiroInicio.subtract(const Duration(hours: 1)),
      diaBase,
    );
    final double maxHoraEixo = _dateTimeToHours(
      ultimoFim.add(const Duration(hours: 1)),
      diaBase,
    );
    final double duracaoTotalEixo = maxHoraEixo - minHoraEixo;

    // --- LÓGICA DE ALOCAÇÃO DAS LINHAS EM NÍVEIS (PISTAS) ---
    List<LineChartBarData> linhasDeExercicio = [];
    List<DateTime> fimDaUltimaSessaoPorNivel = [];
    int nivelMaximo = 0;

    for (var sessao in sessoesOrdenadas) {
      int nivelY = -1;

      // Encontra o primeiro nível disponível
      for (int i = 0; i < fimDaUltimaSessaoPorNivel.length; i++) {
        if (!sessao.inicio.isBefore(fimDaUltimaSessaoPorNivel[i])) {
          nivelY = i;
          break;
        }
      }

      // Se não encontrou nível, cria um novo
      if (nivelY == -1) {
        nivelY = fimDaUltimaSessaoPorNivel.length;
        fimDaUltimaSessaoPorNivel.add(sessao.fim);
      } else {
        fimDaUltimaSessaoPorNivel[nivelY] = sessao.fim;
      }

      if (nivelY > nivelMaximo) nivelMaximo = nivelY;

      // Cria os dois pontos (início e fim) para a linha da sessão
      final spots = [
        FlSpot(_dateTimeToHours(sessao.inicio, diaBase), nivelY.toDouble()),
        FlSpot(_dateTimeToHours(sessao.fim, diaBase), nivelY.toDouble()),
      ];

      // Adiciona a nova linha à lista
      linhasDeExercicio.add(
        LineChartBarData(
          spots: spots,
          isStrokeCapRound: true,
          barWidth: 8, // Linha mais grossa para parecer uma barra fina
          color: _getCorPorAtividade(sessao.atividade),
          dotData: FlDotData(show: false), // Esconde os pontos
        ),
      );
    }
    // --- FIM DA LÓGICA DE ALOCAÇÃO ---

    final double larguraDoGrafico = duracaoTotalEixo * 60.0;

    // Tempo total de exercício (como no seu código)
    final totalMinutos = sessoes.fold<int>(
      0,
      (soma, s) => soma + s.fim.difference(s.inicio).inMinutes,
    );
    final totalHoras = totalMinutos ~/ 60;
    final totalMin = totalMinutos % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // 🔹 Gráfico rolável
          SizedBox(
            height: 150, // Altura do container do gráfico
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: max(MediaQuery.of(context).size.width, larguraDoGrafico),
                child: LineChart(
                  LineChartData(
                    minX: minHoraEixo,
                    maxX: maxHoraEixo,
                    minY: -1, // Margem inferior
                    maxY: nivelMaximo + 1.4, // Margem superior dinâmica
                    lineBarsData: linhasDeExercicio,

                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                    ),
                    borderData: FlBorderData(show: false),

                    // Títulos do Eixo Y (níveis) - Opcional, pode remover se preferir
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final hora = value.toInt() % 24;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('${hora}h'),
                            );
                          },
                        ),
                      ),
                    ),

                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touched) {
                            final linhaIndex = linhasDeExercicio.indexOf(
                              touched.bar,
                            );
                            final sessao = sessoesOrdenadas[linhaIndex];

                            final nomeAtividade = getNomeExercicio(
                              sessao.atividade,
                            );
                            final duracao =
                                sessao.fim.difference(sessao.inicio).inMinutes;

                            return LineTooltipItem(
                              "$nomeAtividade\n${duracao} min",
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 Metas e botão
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FutureBuilder<MetasUsuario>(
              future: _pegarMetas(), // <-- aqui pegamos direto
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 52);
                }

                if (!snapshot.hasData) return const SizedBox.shrink();

                final metas = snapshot.data!;
                final int metaExercicio = metas.exercicios.toInt();
                final String metaFormatada = '${metaExercicio} h';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total: ${totalHoras}h ${totalMin}m | Meta: $metaFormatada',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MetricsPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2C274C),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Acessar dados detalhados >'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
