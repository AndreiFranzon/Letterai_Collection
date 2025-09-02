import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:letterai_colletion/Health/support/acitivities.dart' as support;
import 'package:letterai_colletion/Health/support/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final health = Health();

Future<void> sincronizarDadosContinuos() async {
  final now = DateTime.now();
  final meiaNoite = DateTime(now.year, now.month, now.day);

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('O usuário não está logado');
    return;
  }

  final userId = user.uid;
  final dadosDiariosRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('dados_diarios');

  //Última sincronização
  final totalDoc = await dadosDiariosRef.doc('total_diario').get();
  DateTime ultimoSync = DateTime.fromMicrosecondsSinceEpoch(0);
  if (totalDoc.exists && totalDoc.data()?['sincronizado_em'] != null) {
    ultimoSync = (totalDoc.data()?['sincronizado_em'] as Timestamp).toDate();
  }

  //Determinar qual tipo de busca será usada
  final snapshot = await dadosDiariosRef.get();

  DateTime inicioBusca;
  if (snapshot.docs.isEmpty) {
    inicioBusca = meiaNoite;
  } else {
    inicioBusca = ultimoSync;
  }

  // Tipos de dados a serem buscados
  List<HealthDataType> tiposContinuos =
      (Platform.isAndroid ? dataTypesAndroid : dataTypesIOS)
          .where(
            (type) =>
                type == HealthDataType.WORKOUT ||
                type == HealthDataType.SLEEP_LIGHT ||
                type == HealthDataType.SLEEP_DEEP ||
                type == HealthDataType.SLEEP_REM ||
                type == HealthDataType.SLEEP_ASLEEP ||
                type == HealthDataType.SLEEP_SESSION,
          )
          .toList();

  // Buscar dados desde o dia anterior para garantir pegar sessões iniciadas antes de meia-noite
  final dadosContinuos = await health.getHealthDataFromTypes(
    startTime: inicioBusca,
    endTime: now,
    types: tiposContinuos,
  );

  // Processar sessões de sono
  final sleepSessions =
      dadosContinuos
          .where(
            (dado) =>
                dado.type == HealthDataType.SLEEP_SESSION &&
                dado.dateTo.isAfter(meiaNoite) &&
                dado.dateTo.isBefore(now),
          ) // Sessão termina hoje
          .toList();

  double duracaoSonoHoras = 0;
  final Map<String, Map<String, dynamic>> mapaSleepSessions = {};

  int i = 0;
  for (var session in sleepSessions) {
    final inicio = session.dateFrom;
    final fim = session.dateTo;
    final duracao = fim.difference(inicio).inMinutes / 60.0;
    duracaoSonoHoras += duracao;

    mapaSleepSessions[i.toString()] = {
      'hora_inicio': inicio.toIso8601String(),
      'hora_fim': fim.toIso8601String(),
    };
    i++;
  }

  if (sleepSessions.isNotEmpty) {
    final session = sleepSessions.first; // pega a única sessão do dia
    await dadosDiariosRef.doc('sleep_session').set({
      'hora_inicio': session.dateFrom.toIso8601String(),
      'hora_fim': session.dateTo.toIso8601String(),
    });
    debugPrint('Sessão de sono salva: ${session.dateFrom} - ${session.dateTo}');
  } else {
    debugPrint('Nenhuma sessão de sono encontrada');
  }

  // Processar tipos de sono (light, deep, rem)
  final outrosTipos = dadosContinuos.where(
    (dado) =>
        (dado.type == HealthDataType.SLEEP_LIGHT ||
            dado.type == HealthDataType.SLEEP_DEEP ||
            dado.type == HealthDataType.SLEEP_REM) &&
        dado.dateTo.isAfter(meiaNoite) &&
        dado.dateTo.isBefore(now),
  );

  final Map<String, Map<String, dynamic>> mapaTiposSono = {};
  int contador = 0;
  for (var item in outrosTipos) {
    mapaTiposSono[contador.toString()] = {
      'hora_inicio': item.dateFrom.toIso8601String(),
      'hora_fim': item.dateTo.toIso8601String(),
      'tipo': item.type.toString().split('.').last,
    };
    contador++;
  }

  if (mapaTiposSono.isNotEmpty) {
    await dadosDiariosRef
        .doc('sleep_types')
        .set(mapaTiposSono, SetOptions(merge: true));
  } else {
    await dadosDiariosRef.doc('sleep_types').set({'status': 'no_data'});
    debugPrint('Tipos de sono não encontrados');
  }

  // Processar exercícios físicos (workouts)
  final mapaAtividades = support.gerarMapaAtividades();
  final dadosWorkout =
      dadosContinuos.where((dado) {
        if (dado.type != HealthDataType.WORKOUT) return false;

        final inicio = dado.dateFrom;
        final fim = dado.dateTo;

        // Verifica se algum trecho do workout está dentro do dia
        return (inicio.isBefore(now) && fim.isAfter(meiaNoite));
      }).toList();

  double duracaoExerciciosMinuto = 0;
  final Map<String, Map<String, dynamic>> mapaWorkouts = {};
  int contadorWorkout = 0;

  for (var item in dadosWorkout) {
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

    final inicio = item.dateFrom;
    final fim = item.dateTo;

    mapaWorkouts[contadorWorkout.toString()] = {
      'hora_inicio': inicio.toIso8601String(),
      'hora_fim': fim.toIso8601String(),
      'atividade': atividadeId,
    };

    final duracao = fim.difference(inicio).inMinutes.toDouble();
    duracaoExerciciosMinuto += duracao;

    contadorWorkout++;
  }

  if (mapaWorkouts.isNotEmpty) {
    await dadosDiariosRef
        .doc('workouts')
        .set(mapaWorkouts, SetOptions(merge: true));
  } else {
    debugPrint('Nenhum dado de exercício físico encontrado');
  }

  // Salvar total diário usando FieldValue.increment
  await dadosDiariosRef.doc("total_diario").set({
    'sono': {'duracao_horas': FieldValue.increment(duracaoSonoHoras)},
    'exercicios': {'duracao_minutos': FieldValue.increment(duracaoExerciciosMinuto)},
    'sincronizado_em': Timestamp.now(),
  }, SetOptions(merge: true));
  debugPrint('Total diário de sono e exercícios salvos');
}
