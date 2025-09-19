import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    sync(false);
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    sync(false);
    return;
  }

  final userId = user.uid;

  final ultimoDocSnapshot =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('dados_permanentes')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

  DateTime diaAlvo;
  if (ultimoDocSnapshot.docs.isEmpty) {
    diaAlvo = DateTime.now().subtract(const Duration(days: 1));
  } else {
    final ultimoDiaId = ultimoDocSnapshot.docs.first.id;
    diaAlvo = DateTime.parse(ultimoDiaId).add(const Duration(days: 1));
  }

  final ontem = DateTime.now().subtract(const Duration(days: 1));

  while (!diaAlvo.isAfter(ontem)) {
    await sincronizarDadosFixosPermantentes(diaAlvo);
    await sincronizarDadosContinuosPermanentes(diaAlvo);

    try {
      final pontosAmarelos = await calcularPontosAmarelos(diaAlvo);
      final pontosRoxos = await calcularPontosRoxos(diaAlvo);

      final xp = pontosAmarelos + pontosRoxos;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await salvarXpPlayer(user.uid, xp);
        await salvarXpCard(userId, xp);
      }
    } catch (e) {
      debugPrint("Erro ao calcular pontos: $e");
    }

    diaAlvo = diaAlvo.add(const Duration(days: 1));
  }

  sync(false);
}

Future<void> salvarXpPlayer(String userId, int xpGanho) async {
  final nivelDoc = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('estatisticas')
      .doc('nivel');

  final nivelSnap = await nivelDoc.get();
  int nivel = nivelSnap.data()?['nivel'] ?? 1;
  int xpAtual = nivelSnap.data()?['xp'] ?? 0;

  int xpTotal = xpAtual + xpGanho;
  int xpNecessario = 50 + (50 * nivel);

  while (xpTotal >= xpNecessario) {
    xpTotal -= xpNecessario;
    nivel += 1;
    xpNecessario = 50 + (50 * nivel);
  }

  await nivelDoc.update({
    'nivel': nivel,
    'xp': xpTotal,
  });
}

Future<void> salvarXpCard(String userId, int xpGanho) async {
  final firestore = FirebaseFirestore.instance;

  final cartaAtivaDoc = await firestore
      .collection('usuarios')
      .doc(userId)
      .collection('inventario')
      .doc('itens')
      .collection('carta_ativa')
      .doc('selecionada')
      .get();

  if (!cartaAtivaDoc.exists) return;

  final cartaId = cartaAtivaDoc.data()?['id'];
  if (cartaId == null) return;

  final cartaDoc = firestore
      .collection('usuarios')
      .doc(userId)
      .collection('inventario')
      .doc('itens')
      .collection('colecao')
      .doc(cartaId);

  final cartaSnap = await cartaDoc.get();
  int nivelCarta = cartaSnap.data()?['nivel'] ?? 1;
  int xpCarta = cartaSnap.data()?['xp'] ?? 0;
  int pontosAtuais = cartaSnap.data()?['pontos_ganhos'] ?? 0;

  int xpTotalCarta = xpCarta + xpGanho;
  int xpNecessarioCarta = 50 + (50 * nivelCarta); // XP necessário da carta

  while (xpTotalCarta >= xpNecessarioCarta) {
    xpTotalCarta -= xpNecessarioCarta;
    nivelCarta += 1;
    xpNecessarioCarta = 50 + (50 * nivelCarta);
  }

  await cartaDoc.update({
    'nivel': nivelCarta,
    'xp': xpTotalCarta,
    'pontos_ganhos': pontosAtuais + 6,
  });
}
