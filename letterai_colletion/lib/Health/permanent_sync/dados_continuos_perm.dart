import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:letterai_colletion/Health/support/util.dart';
import 'package:letterai_colletion/Health/support/acitivities.dart' as support;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


final health = Health();

Future<void> sincronizarDadosContinuosPermanentes() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(hours: 30));
    final startDataWorkout = endDate.subtract(const Duration(hours: 24));
    final padraoHoraFormatada = endDate.subtract(const Duration(hours: 24));

    final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('O usuário não está logado');
        return;
      }
    
  final userId = user.uid;

  final dataFormatada = DateFormat('yyyy-MM-dd').format(padraoHoraFormatada);


    List<HealthDataType> tiposContinuos = (Platform.isAndroid ? dataTypesAndroid : dataTypesIOS)
      .where((type) =>
        type == HealthDataType.WORKOUT ||
        type == HealthDataType.SLEEP_LIGHT ||
        type == HealthDataType.SLEEP_DEEP ||
        type == HealthDataType.SLEEP_REM ||
        type == HealthDataType.SLEEP_ASLEEP ||
        type == HealthDataType.SLEEP_SESSION)
    .toList();

    final dadosContinuosSono = await health.getHealthDataFromTypes(
      startTime: startDate,
      endTime: endDate,
      types: tiposContinuos.where((type) => 
        type == HealthDataType.SLEEP_LIGHT ||
        type == HealthDataType.SLEEP_DEEP ||
        type == HealthDataType.SLEEP_REM ||
        type == HealthDataType.SLEEP_ASLEEP ||
        type == HealthDataType.SLEEP_SESSION).toList(),
    );
    
    final dadosContinuosWorkout = await health.getHealthDataFromTypes(
      startTime: startDataWorkout, 
      endTime: endDate,
      types: tiposContinuos.where((type) => type == HealthDataType.WORKOUT). toList(),
    );
    
    final sleepSession = dadosContinuosSono.where((dado) => dado.type == HealthDataType.SLEEP_SESSION).toList();
    final outrosTipos = dadosContinuosSono.where((dado) =>
      dado.type == HealthDataType.SLEEP_LIGHT ||
      dado.type == HealthDataType.SLEEP_DEEP ||
      dado.type == HealthDataType.SLEEP_REM ||
      dado.type == HealthDataType.SLEEP_ASLEEP
    ).toList();

    final dadosPermanentesRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('dados_permanentes')
      .doc(dataFormatada);

    if (sleepSession.isNotEmpty) {
      final inicio = sleepSession.first.dateFrom;
      final fim = sleepSession.first.dateTo;

      await dadosPermanentesRef.set({
        'sleep_session': {
          'hora_inicio': inicio.toIso8601String(),
          'hora_fim': fim.toIso8601String(),
        }
      }, SetOptions(merge: true));
    } else {
      await dadosPermanentesRef.set({
        'sleep_session': {'status': 'no_data'}
      }, SetOptions(merge: true));
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
      await dadosPermanentesRef.set({
        'sleep_types': mapaTiposSono,
      }, SetOptions(merge:true));
    } else {
      await dadosPermanentesRef.set({
        'sleep_types': {'status': 'no_data'},
      }, SetOptions(merge: true));
      debugPrint ('Tipos de sono não encontrados');
    }

    //-x+x- Dados de exercício físico
    final mapaAtividades = support.gerarMapaAtividades();

    final dadosWorkout = dadosContinuosWorkout.where((dado) => dado.type == HealthDataType.WORKOUT).toList();

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
      
      await dadosPermanentesRef.set({
        'workouts': mapaWorkouts,
      }, SetOptions(merge: true));
    } else {
      await dadosPermanentesRef.set({
          'workouts': {'status': 'no_data'},
        }, SetOptions(merge: true));

      debugPrint('Nenhum dado de exercício físico encontrado');
    }
}

