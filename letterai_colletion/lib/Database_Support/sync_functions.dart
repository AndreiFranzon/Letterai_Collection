import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:letterai_colletion/Health/support/util.dart';

import 'package:letterai_colletion/Health/diary_sync/dados_fixos.dart';
import 'package:letterai_colletion/Health/diary_sync/dados_continuos.dart';

import 'package:letterai_colletion/Health/permanent_sync/dados_fixos_perm.dart';
import 'package:letterai_colletion/Health/permanent_sync/dados_continuos_perm.dart';

import 'package:letterai_colletion/Game/score.dart';

final health = Health();
bool sync = false;

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
  HEALTH_CONNECT_STATUS,
  PERMISSIONS_REVOKING,
  PERMISSIONS_REVOKED,
  PERMISSIONS_NOT_REVOKED,
}

// All types available depending on platform (iOS ot Android).
  List<HealthDataType> get types =>
      (Platform.isAndroid)
          ? dataTypesAndroid
          : (Platform.isIOS)
          ? dataTypesIOS
          : [];

  List<HealthDataAccess> get permissions =>
      types
          .map(
            (type) =>
                // can only request READ permissions to the following list of types on iOS
                [
                      HealthDataType.APPLE_MOVE_TIME,
                      HealthDataType.APPLE_STAND_HOUR,
                      HealthDataType.APPLE_STAND_TIME,
                      HealthDataType.WALKING_HEART_RATE,
                      HealthDataType.ELECTROCARDIOGRAM,
                      HealthDataType.HIGH_HEART_RATE_EVENT,
                      HealthDataType.LOW_HEART_RATE_EVENT,
                      HealthDataType.IRREGULAR_HEART_RATE_EVENT,
                      HealthDataType.EXERCISE_TIME,
                    ].contains(type)
                    ? HealthDataAccess.READ
                    : HealthDataAccess.READ_WRITE,
          )
          .toList();

Future<void> installHealthConnect() async =>
      await health.installHealthConnect();

Future<bool> verificarPermissoes() async {
  if (!Platform.isAndroid) {
    return false;
  }

  final temPermissoes = await health.hasPermissions(
    types,
    permissions: permissions,
  );

  return temPermissoes == true;
}

Future<void> sincronizarTudo({required Function(bool) sync}) async {
  sync(true);

  final permissoesOk = await verificarPermissoes();
  if (!permissoesOk) {
    await installHealthConnect();
    return;
  }

  await sincronizarDadosFixos();
  //debugPrint('Dados fixos sincronizados');
  await sincronizarDadosContinuos();
  //debugPrint('Dados continuos sincronizados');

  sync(false);
}


  Future<void> sincronizarTudoPerm({required Function(bool) sync}) async {
  sync(true);
  
  final permissoesOk = await verificarPermissoes();
  if (!permissoesOk) {
    installHealthConnect();
  }

  await sincronizarDadosFixosPermantentes();
  await sincronizarDadosContinuosPermanentes();

  try {
    final pontosAmarelos = await calcularPontosAmarelos();
    final pontosRoxos = await calcularPontosRoxos();
    sync(false);
    
    debugPrint("Pontuação final do dia: ${pontosAmarelos + pontosRoxos}");
  } catch (e) {
    debugPrint("Erro ao calcular pontos: $e");
  }
}
