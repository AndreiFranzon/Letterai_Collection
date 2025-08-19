import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;
import 'package:intl/intl.dart';

import 'package:letterai_colletion/Health/graphics/data/diary_data.dart';
import 'package:letterai_colletion/Health/graphics/data/perm_data.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  String tipoSelecionado = 'SLEEP_SESSION';
  bool modoDiario = true;
  bool mostrarCalendario = false;
  late Future<List<String>> dadosFuturo;
  String? userId;

  DateTime _selectedDay = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      dadosFuturo = _buscarDadosSelecionados();
    }
  }

  Future<List<String>> _buscarDadosSelecionados({DateTime? dia}) {
    if (userId == null) return Future.value([]);

    final dataFiltrada = dia ?? _selectedDay;

    if (modoDiario) {
          return buscarSonoDiario(userId!);
    } else {
        return buscarSonoPermanente(userId!, dia: dataFiltrada);
    }
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
          
          if (!modoDiario)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Setinha para o dia anterior
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

                      // Data centralizada
                      Expanded(
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                mostrarCalendario = !mostrarCalendario;
                              });
                            },
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(_selectedDay),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),

                      // Setinha para o próximo dia
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

                  // Calendário abaixo da data
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

          //Carrega os dados
          Expanded(
            child: FutureBuilder<List<String>>(
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

                final dadosSono = snapshot.data!;
                final inicio = DateTime.tryParse(dadosSono[0]) ?? DateTime.now();
                final fim = DateTime.tryParse(dadosSono[1]) ?? DateTime.now();

                final fimAjustado = fim.isBefore(inicio) ? fim.add(const Duration(days: 1)) : fim;

                final duracao = fimAjustado.difference(inicio);
                final horas = duracao.inHours;
                final minutos = duracao.inMinutes % 60;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duracão do sono: $horas h $minutos min',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox( height: 20),

                      Expanded(
                        child: ListView(
                          children: [
                            ListTile(
                              title: const Text('Início do sono'),
                              trailing: Text(
                                '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                            ListTile(
                              title: const Text('Fim do sono'),
                              trailing: Text(
                                '${fimAjustado.hour.toString().padLeft(2, '0')}:${fimAjustado.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ],
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
