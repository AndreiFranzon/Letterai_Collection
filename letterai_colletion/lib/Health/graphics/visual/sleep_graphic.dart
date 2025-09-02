import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:letterai_colletion/Health/graphics/return_daily_goal.dart';
import 'package:letterai_colletion/Database_Support/exercise_data.dart';
import 'package:letterai_colletion/Health/graphics/sleep_page.dart';

class SleepGraphic extends StatelessWidget {
  final Future<MetasUsuario> metasFuture;

  const SleepGraphic({super.key, required this.metasFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Consumer<dadosDiariosProvider>(
            builder: (context, dados, child) {
              if (dados.sessoesSono.isEmpty || dados.sessoesSono.length < 2) {
                return const Center(
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: Text("Dados de sono não sincronizados"),
                    ),
                  ),
                );
              }

              final horaInicio = DateTime.parse(dados.sessoesSono[0]);
              final horaFim = DateTime.parse(dados.sessoesSono[1]);

              double inicioHoras =
                  horaInicio.hour + horaInicio.minute / 60.0;

              int diasDeDiferenca =
                  horaFim.difference(horaInicio).inDays;
              double fimHoras =
                  (horaFim.hour + horaFim.minute / 60.0) +
                  (diasDeDiferenca * 24);

              if (fimHoras < inicioHoras && diasDeDiferenca == 0) {
                fimHoras += 24;
              }

              final minHoraEixo = inicioHoras;
              final maxHoraEixo = fimHoras;

              return Container(
                height: 120,
                padding: const EdgeInsets.only(top: 24, right: 12, left: 12),
                decoration: BoxDecoration(
                  color: const Color(0xff2c274c),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final double totalSono = dados.totalSono;
                            final int horas = totalSono.toInt();
                            final int minutos =
                                ((totalSono - horas) * 60).round();

                            String text = '${horas}h ${minutos}m';

                            return LineTooltipItem(
                              text,
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    minX: minHoraEixo - 1,
                    maxX: maxHoraEixo + 1,
                    minY: -0.2,
                    maxY: 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(minHoraEixo, 0),
                          FlSpot(inicioHoras, 0),
                          FlSpot(inicioHoras, 1),
                          FlSpot(fimHoras, 1),
                          FlSpot(fimHoras, 0),
                          FlSpot(maxHoraEixo, 0),
                        ],
                        isCurved: false,
                        color: const Color(0xffa27dfd),
                        barWidth: 4,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffa27dfd).withOpacity(0.5),
                              const Color(0xffa27dfd).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: const Color(0xff4a417c),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xff4a417c),
                          width: 2,
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
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
                              child: Text(
                                '${hora}h',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 🔹 Metas e botão
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: FutureBuilder<MetasUsuario>(
            future: metasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 52);
              }

              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final metas = snapshot.data!;
              final int horasMeta = metas.sono.toInt();
              final String metaFormatada = '${horasMeta}:00h';

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Meta: $metaFormatada',
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
                          builder: (_) => const SleepPage(),
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
    );
  }
}
