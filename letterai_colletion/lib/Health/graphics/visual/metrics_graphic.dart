import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:letterai_colletion/Health/graphics/return_daily_goal.dart';
import 'package:letterai_colletion/Health/graphics/metrics_page.dart';

class BarChartGeneric extends StatelessWidget {
  final List<int> valores; // Lista com 24 valores, 1 por hora
  final String titulo;
  final Color corBarra;
  final int? tipoMetrica;
  final int total;

  const BarChartGeneric({
    Key? key,
    required this.valores,
    required this.titulo,
    required this.corBarra,
    required this.tipoMetrica,
    required this.total,
  }) : super(key: key);

  Future<int> _pegarMeta() async {
    final metas = await buscarMetasUsuario(
      FirebaseAuth.instance.currentUser!.uid,
    );

    if (tipoMetrica == 0) {
      return metas.passos.toInt();
    } else if (tipoMetrica == 1) {
      return metas.distancia.toInt();
    } else if (tipoMetrica == 2) {
      return metas.calorias;
    } else {
      return 0; // valor padrão caso não seja nenhum dos três
    }
  }

  @override
  Widget build(BuildContext context) {
    final double larguraBarra = 12;
    final double espacamento = 20;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: max(
                24 * (larguraBarra + espacamento),
                MediaQuery.of(context).size.width,
              ),
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY:
                      valores.isNotEmpty
                          ? valores.reduce(max).toDouble() * 1.2
                          : 10,
                  barGroups: List.generate(24, (i) {
                    final valor = i < valores.length ? valores[i] : 0;
                    return BarChartGroupData(
                      x: i,
                      barsSpace: espacamento,
                      barRods: [
                        BarChartRodData(
                          toY: valor.toDouble(),
                          color: corBarra,
                          width: larguraBarra,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 0,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
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
                        getTitlesWidget: (value, meta) {
                          final int hora = value.toInt();
                          return Text(
                            '${hora}h',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          //Total diário
          FutureBuilder<int>(
            future: _pegarMeta(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 40);
              }
              if (!snapshot.hasData) return const SizedBox.shrink();

              final int meta = snapshot.data!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total: $total | Meta: $meta',
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
                        MaterialPageRoute(builder: (_) => const MetricsPage()),
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
        ],
      ),
    );
  }
}
