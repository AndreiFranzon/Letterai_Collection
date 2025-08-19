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
    final outrosTipos = dadosContinuos.where((dado) =>
      dado.type == HealthDataType.SLEEP_LIGHT ||
      dado.type == HealthDataType.SLEEP_DEEP ||
      dado.type == HealthDataType.SLEEP_REM
    ).toList();

    if (sleepSession.isNotEmpty) {
      final inicio = sleepSession.first.dateFrom;
      final fim = sleepSession.first.dateTo;

      await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('sleep_session')
        .set({
          'hora_inicio': inicio.toIso8601String(),
          'hora_fim': fim.toIso8601String(),
        });
    } else {
      await FirebaseFirestore.instance
      .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('sleep_session')
        .set({
          'status': 'no_data',
        });
      debugPrint('Dados de sono vazios');
    }

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
      await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('sleep_types')
        .set(mapaTiposSono);
    } else {
      await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('sleep_types')
        .set({
            'status': 'no_data',
          });

      debugPrint ('Tipos de sono não encontrados');
    }

    //-x+x- Dados de exercício físico
    
    final mapaAtividades = support.gerarMapaAtividades();

    final dadosWorkout = dadosContinuos.where((dado) => dado.type == HealthDataType.WORKOUT).toList();

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
      }
      
      await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('workouts')
        .set(mapaWorkouts);
    } else {
      await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('dados_diarios')
        .doc('workouts')
        .set({
          'status': 'no_data',
        });

      debugPrint('Nenhum dado de exercício físico encontrado');
    }
  }