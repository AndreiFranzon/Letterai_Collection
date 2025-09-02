import 'dart:async';
//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> carregarDadosDiarios() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('O usuário não está logado');
    return;
  }

  //final userId = user.uid;
}

int totalPassosDiario = 0;
int totalCaloriasDiarias = 0;
int totalDistanciaDiaria = 0;
double totalSonoDiario = 0;
double totalExercicioDiario = 0;

Future<List<int>> buscarPassosDiarios(String userId) async {
  List<int> passos = [];

  final metrica = 'STEPS';
  int totalDiarioPassos = await buscarTotalMetricasDiarias(userId, metrica);

  totalPassosDiario = totalDiarioPassos;

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('dados_diarios')
            .doc(hora)
            .get();

    if (doc.exists) {
      final dados = doc.data()?['dados'] as List<dynamic>? ?? [];

      final step = dados.firstWhere(
        (element) => element['tipo'] == 'STEPS',
        orElse: () => {'valor': 0},
      );
      passos.add(step['valor'] ?? 0);
    } else {
      passos.add(0);
    }
  }

  return passos;
}

Future<List<int>> buscarCaloriasDiarias(String userId) async {
  List<int> caloriasDiarias = [];

  final metrica = 'TOTAL_CALORIES_BURNED';
  int totalDiarioCalorias = await buscarTotalMetricasDiarias(userId, metrica);

  totalCaloriasDiarias = totalDiarioCalorias;

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('dados_diarios')
            .doc(hora)
            .get();

    if (doc.exists) {
      final dados = doc.data()?['dados'] as List<dynamic>? ?? [];

      final calories = dados.firstWhere(
        (element) => element['tipo'] == 'TOTAL_CALORIES_BURNED',
        orElse: () => {'valor': 0},
      );
      caloriasDiarias.add((calories['valor'] as num?)?.toInt() ?? 0);
    } else {
      caloriasDiarias.add(0);
    }
  }

  return caloriasDiarias;
}

Future<List<int>> buscarDistanciaDiaria(String userId) async {
  List<int> distanciaDiaria = [];

  final metrica = 'DISTANCE_DELTA';
  int totalDiarioDistancia = await buscarTotalMetricasDiarias(userId, metrica);

  totalDistanciaDiaria = totalDiarioDistancia;

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('dados_diarios')
            .doc(hora)
            .get();

    if (doc.exists) {
      final dados = doc.data()?['dados'] as List<dynamic>? ?? [];

      final distance = dados.firstWhere(
        (element) => element['tipo'] == 'DISTANCE_DELTA',
        orElse: () => {'valor': 0},
      );
      distanciaDiaria.add((distance['valor'] as num?)?.toInt() ?? 0);
    } else {
      distanciaDiaria.add(0);
    }
  }

  return distanciaDiaria;
}

Future<List<String>> buscarSonoDiario(String userId) async {
  double totalDiarioSono = await buscarTotalSonoDiario(userId);
  totalSonoDiario = totalDiarioSono;

  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('dados_diarios')
            .doc('sleep_session')
            .get();

    if (!doc.exists) {
      return [];
    }

    final data = doc.data();
    if (data == null) {
      return [];
    }

    final inicio = data['hora_inicio'] as String?;
    final fim = data['hora_fim'] as String?;

    if (inicio != null && inicio.isNotEmpty && fim != null && fim.isNotEmpty) {
      return [inicio, fim];
    } else {
      return [];
    }
  } catch (e) {
    print('Erro ao buscar dados de sono: $e');
    return [];
  }
}

Future<List<int>> buscarExercicioDiario(String userId) async {
  List<int> listaWorkouts = [];

  double totalDiarioExercicio = await buscarTotalExercicioDiario(userId);

  totalExercicioDiario = totalDiarioExercicio;

  final doc =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('dados_diarios')
          .doc('workouts')
          .get();

  if (!doc.exists) return listaWorkouts;

  final dados = doc.data() ?? {};

  dados.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      final atividade =
          value['atividade'] is int ? value['atividade'] as int : 0;
      final horaInicio = DateTime.parse(value['hora_inicio']);
      final horaFim = DateTime.parse(value['hora_fim']);

      final inicio = horaInicio.hour * 100 + horaInicio.minute;
      final fim = horaFim.hour * 100 + horaFim.minute;

      listaWorkouts.addAll([atividade, inicio, fim]);
    }
  });

  return listaWorkouts;
}

//==========X+Retorno de soma dos valores+X==========\\

Future<int> buscarTotalMetricasDiarias(String userId, String metrica) async {
  try {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('total_diario');

    final snapshot = await docRef.get();
    if (!snapshot.exists) return 0;

    final data = snapshot.data();
    if (data == null || !data.containsKey('atividade')) return 0;

    final atividadeMap = data['atividade'] as Map<String, dynamic>;
    final valor = atividadeMap[metrica];

    if (valor is int) return valor;
    if (valor is double) return valor.toInt();

    debugPrint('Dados buscados com sucesso');

    return 0;
  } catch (e) {
    debugPrint('Erro ao buscar total de passos diários: $e');
    return 0;
  }
}

Future<double> buscarTotalExercicioDiario(String userId) async {
  try {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('total_diario');

    final snapshot = await docRef.get();
    if (!snapshot.exists) return 0.0;

    final data = snapshot.data();
    if (data == null || !data.containsKey('exercicios')) return 0.0;

    final exerciciosMap = data['exercicios'] as Map<String, dynamic>;
    final valor = exerciciosMap['duracao_minutos'];

    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;

    return 0.0;
  } catch (e) {
    debugPrint('Erro ao buscar total de exercícios diários: $e');
    return 0.0;
  }
}

Future<double> buscarTotalSonoDiario(String userId) async {
  try {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('total_diario');

    final snapshot = await docRef.get();
    if (!snapshot.exists) return 0.0;

    final data = snapshot.data();
    if (data == null || !data.containsKey('sono')) return 0.0;

    final sonoMap = data['sono'] as Map<String, dynamic>;
    final valor = sonoMap['duracao_horas'];

    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;

    return 0.0;
  } catch (e) {
    debugPrint('Erro ao buscar total de sono diario: $e');
    return 0.0;
  }
}
