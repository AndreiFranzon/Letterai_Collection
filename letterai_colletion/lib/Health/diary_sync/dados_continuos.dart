import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:letterai_colletion/Health/support/acitivities.dart' as support;
import 'package:letterai_colletion/Health/support/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


final health = Health();

Future<void> sincronizarDadosContinuos () async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(hours: 24));

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

    List<HealthDataType> tiposContinuos = (Platform.isAndroid ? dataTypesAndroid : dataTypesIOS)
      .where((type) =>
        type == HealthDataType.WORKOUT ||
        type == HealthDataType.SLEEP_LIGHT ||
        type == HealthDataType.SLEEP_DEEP ||
        type == HealthDataType.SLEEP_REM ||
        type == HealthDataType.SLEEP_ASLEEP ||
        type == HealthDataType.SLEEP_SESSION)
    .toList();

    final dadosContinuos = await health.getHealthDataFromTypes(
      startTime: startDate,
      endTime: endDate,
      types: tiposContinuos,
    );
  
    final sleepSession = dadosContinuos.where((dado) => dado.type == HealthDataType.SLEEP_SESSION).toList();
    
    double duracaoSonoHoras = 0;

    if (sleepSession.isNotEmpty) {
      final inicio = sleepSession.first.dateFrom;
      final fim = sleepSession.first.dateTo;
      duracaoSonoHoras = fim.difference(inicio).inMinutes / 60.0;

      await dadosDiariosRef.doc('sleep_session').set({
        'hora_inicio': inicio.toIso8601String(),
        'hora_fim': fim.toIso8601String(),
      });
    } else {
      await dadosDiariosRef.doc('sleep_session').set({'status': 'no_data'});
      debugPrint('Dados de sono vazios');
    }
    
    final outrosTipos = dadosContinuos.where((dado) =>
      dado.type == HealthDataType.SLEEP_LIGHT ||
      dado.type == HealthDataType.SLEEP_DEEP ||
      dado.type == HealthDataType.SLEEP_REM
    ).toList();

    final Map<String, Map<String, dynamic>> mapaTiposSono = {};

    for (int i = 0; i < outrosTipos.length; i++){
      final item = outrosTipos[i];
      mapaTiposSono[i.toString()] = {
        'hora_inicio': item.dateFrom.toIso8601String(),
        'hora_fim': item.dateTo.toIso8601String(),
        'tipo': item.type.toString().split('.').last,
      };
    }

    if (mapaTiposSono.isNotEmpty){
      await dadosDiariosRef.doc('sleep_types').set(mapaTiposSono);
    } else {
      await dadosDiariosRef.doc('sleep_types').set({'status': 'no_data',});
      debugPrint ('Tipos de sono não encontrados');
    }

    //-x+x- Dados de exercício físico
    
    final mapaAtividades = support.gerarMapaAtividades();
    final dadosWorkout = dadosContinuos.where((dado) => dado.type == HealthDataType.WORKOUT).toList();

    double duracaoExerciciosMinuto = 0;

    if (dadosWorkout.isNotEmpty) {
      final Map<String, Map<String, dynamic>> mapaWorkouts = {};

      for (int i = 0; i < dadosWorkout.length; i++) {
        final item = dadosWorkout[i];
        final workoutValue = item.value as WorkoutHealthValue;

        final atividadeNome = workoutValue.workoutActivityType
            ?.toString()
            .split('.')
            .last ??
        'OTHER';

        final atividadeId = mapaAtividades.entries
        .firstWhere(
          (e) => e.key.toString().split('.').last == atividadeNome,
          orElse: () =>
              MapEntry(support.HealthWorkoutActivityType.OTHER, 0),
        )
        .value;

        mapaWorkouts[i.toString()] = {
          'hora_inicio': item.dateFrom.toIso8601String(),
          'hora_fim': item.dateTo.toIso8601String(),
          'atividade': atividadeId,
        };

        duracaoExerciciosMinuto += item.dateTo.difference(item.dateFrom).inMinutes / 60.0;
      }
      
      await dadosDiariosRef.doc('workouts').set(mapaWorkouts);
    } else {
      await dadosDiariosRef.doc('workouts').set({'status': 'no_data',});
      debugPrint('Nenhum dado de exercício físico encontrado');
    }

    await dadosDiariosRef.doc("total_diario").set({
      'sono': {'duracao_horas': duracaoSonoHoras},
      'exercicios': {'duracao_minutos': duracaoExerciciosMinuto},
    }, SetOptions(merge: true));

    debugPrint('Total diário de sono e exercícios salvos');
  }