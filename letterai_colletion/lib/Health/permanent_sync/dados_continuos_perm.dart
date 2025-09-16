import 'dart:async';
//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
//import 'package:letterai_colletion/Health/support/util.dart';
import 'package:letterai_colletion/Health/support/acitivities.dart' as support;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final health = Health();

Future<void> sincronizarDadosContinuosPermanentes(DateTime diaAlvo) async {

  final startSono = DateTime(diaAlvo.year, diaAlvo.month, diaAlvo.day -1, 18, 0, 0);
  final endSono = DateTime(diaAlvo.year, diaAlvo.month, diaAlvo.day, 23, 59, 59);
  
  final startWorkout = DateTime(diaAlvo.year, diaAlvo.month, diaAlvo.day,  0, 0, 0);
  final endWorkout = DateTime(diaAlvo.year, diaAlvo.month, diaAlvo.day, 23, 59, 59);


  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('O usuário não está logado');
    return;
  }

  final userId = user.uid;
  final dataFormatada = DateFormat('yyyy-MM-dd').format(diaAlvo);
  final dadosPermanentesRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('dados_permanentes')
      .doc(dataFormatada);

  List<HealthDataType> tiposSono = [
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_SESSION,
  ];

  final dadosContinuosSono = await health.getHealthDataFromTypes(
    startTime: startSono,
    endTime: endSono,
    types: tiposSono,
  );

  final sleepSession =
      dadosContinuosSono
          .where((dado) => dado.type == HealthDataType.SLEEP_SESSION)
          .toList();
  final outrosTipos =
      dadosContinuosSono
          .where(
            (dado) =>
                dado.type == HealthDataType.SLEEP_LIGHT ||
                dado.type == HealthDataType.SLEEP_DEEP ||
                dado.type == HealthDataType.SLEEP_REM ||
                dado.type == HealthDataType.SLEEP_ASLEEP,
          )
          .toList();

  if (sleepSession.isNotEmpty) {
    final inicio = sleepSession.first.dateFrom;
    final fim = sleepSession.first.dateTo;

    await dadosPermanentesRef.set({
      'sleep_session': {
        'hora_inicio': inicio.toIso8601String(),
        'hora_fim': fim.toIso8601String(),
      },
    }, SetOptions(merge: true));
  } else {
    await dadosPermanentesRef.set({
      'sleep_session': {'status': 'no_data'},
    }, SetOptions(merge: true));
  }

  final Map<String, Map<String, dynamic>> mapaTiposSono = {};

  for (int i = 0; i < outrosTipos.length; i++) {
    final item = outrosTipos[i];
    mapaTiposSono[i.toString()] = {
      'hora_inicio': item.dateFrom.toIso8601String(),
      'hora_fim': item.dateTo.toIso8601String(),
      'tipo': item.type.toString().split('.').last,
    };
  }

  if (mapaTiposSono.isNotEmpty) {
    await dadosPermanentesRef.set({
      'sleep_types': mapaTiposSono,
    }, SetOptions(merge: true));
  } else {
    await dadosPermanentesRef.set({
      'sleep_types': {'status': 'no_data'},
    }, SetOptions(merge: true));
    debugPrint('Tipos de sono não encontrados');
  }

  //-x+x- Dados de exercício físico
  final mapaAtividades = support.gerarMapaAtividades();
  final dadosContinuosWorkout = await health.getHealthDataFromTypes(
    startTime: startWorkout,
    endTime: endWorkout,
    types: [HealthDataType.WORKOUT],
  );
  final dadosWorkout =
      dadosContinuosWorkout
          .where((dado) => dado.type == HealthDataType.WORKOUT)
          .toList();

  double duracaoExerciciosHoras = 0;
  final Map<String, Map<String, dynamic>> mapaWorkouts = {};

  for (int i = 0; i < dadosWorkout.length; i++) {
    final item = dadosWorkout[i];
    final workoutValue = item.value as WorkoutHealthValue;

    final atividadeNome =
        workoutValue.workoutActivityType?.toString().split('.').last ?? 'OTHER';

    final atividadeId =
        mapaAtividades.entries
            .firstWhere(
              (e) => e.key.toString().split('.').last == atividadeNome,
              orElse:
                  () => MapEntry(support.HealthWorkoutActivityType.OTHER, 0),
            )
            .value;

    mapaWorkouts[i.toString()] = {
      'hora_inicio': item.dateFrom.toIso8601String(),
      'hora_fim': item.dateTo.toIso8601String(),
      'atividade': atividadeId,
    };

    duracaoExerciciosHoras +=
        item.dateTo.difference(item.dateFrom).inMinutes / 60.0;
  }

  if (mapaWorkouts.isNotEmpty) {
    await dadosPermanentesRef.set({
      'workouts': mapaWorkouts,
    }, SetOptions(merge: true));
  } else {
    await dadosPermanentesRef.set({
      'workouts': {'status': 'no_data'},
    }, SetOptions(merge: true));

    debugPrint('Nenhum dado de exercício físico encontrado');
  }

  final totalDiarioRef = dadosPermanentesRef
      .collection('total_diario')
      .doc('totais');

  Map<String, dynamic> totais = {};

  totais['exercicios'] = {'duracao_horas': duracaoExerciciosHoras};

  if (sleepSession.isNotEmpty) {
    final duracaoSono =
        sleepSession.first.dateTo
            .difference(sleepSession.first.dateFrom)
            .inMinutes /
        60.0;
    totais['sono'] = {'duracao_horas': duracaoSono};
  }

  await totalDiarioRef.set({'totais': totais}, SetOptions(merge: true));

  debugPrint('Total diário continuo salvo com sucesso');
}