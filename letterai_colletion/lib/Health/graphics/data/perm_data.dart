import 'dart:async';
//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> carregarDadosPerm() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('O usuário não está logado');
    return;
  }

  //final userId = user.uid;
}

Future<String?> buscarUltimaData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('Usuário não está logado');
    return null;
  }

  final userId = user.uid;

  final querySnapshot =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('dados_permanentes')
          .orderBy(FieldPath.documentId, descending: true) // ordena pela data
          .limit(1)
          .get();

  if (querySnapshot.docs.isEmpty) {
    debugPrint('Nenhum registro encontrado');
    return null;
  }

  // O nome do documento é a data
  return querySnapshot.docs.first.id;
}

Future<List<int>> buscarPassosPermanentes(
  String userId, {
  DateTime? dia,
}) async {
  List<int> passos = [];

  final String dataDoc =
      dia != null
          ? DateFormat('yyyy-MM-dd').format(dia)
          : (await buscarUltimaData()) ?? '';

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    if (dataDoc.isNotEmpty) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('dados_permanentes')
              .doc(dataDoc)
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
  }
  return passos;
}

Future<List<int>> buscarCaloriasPermanentes(
  String userId, {
  DateTime? dia,
}) async {
  List<int> calorias = [];

  final String dataDoc =
      dia != null
          ? DateFormat('yyyy-MM-dd').format(dia)
          : (await buscarUltimaData()) ?? '';

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    if (dataDoc.isNotEmpty) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('dados_permanentes')
              .doc(dataDoc)
              .collection('dados_diarios')
              .doc(hora)
              .get();

      if (doc.exists) {
        final dados = doc.data()?['dados'] as List<dynamic>? ?? [];

        final calories = dados.firstWhere(
          (element) => element['tipo'] == 'TOTAL_CALORIES_BURNED',
          orElse: () => {'valor': 0},
        );
        calorias.add((calories['valor'] as num?)?.toInt() ?? 0);
      } else {
        calorias.add(0);
      }
    }
  }
  return calorias;
}

Future<List<int>> buscarDistanciaPermanente(
  String userId, {
  DateTime? dia,
}) async {
  List<int> distanciaDiaria = [];

  final String dataDoc =
      dia != null
          ? DateFormat('yyyy-MM-dd').format(dia)
          : (await buscarUltimaData()) ?? '';

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    if (dataDoc.isNotEmpty) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('dados_permanentes')
              .doc(dataDoc)
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
  }
  return distanciaDiaria;
}

Future<List<String>> buscarSonoPermanente(
  String userId, {
  DateTime? dia,
}) async {
  List<String> duracaoSono = ['', ''];

  final String dataDoc =
      dia != null
          ? DateFormat('yyyy-MM-dd').format(dia)
          : (await buscarUltimaData()) ?? '';

  final doc =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('dados_permanentes')
          .doc(dataDoc)
          .get();

  if (!doc.exists) return duracaoSono;

  final Map<String, dynamic> data = doc.data() ?? {};

  final sleepSession = data['sleep_session'];
  if (sleepSession is Map<String, dynamic>) {
    final inicio = (sleepSession['hora_inicio'] as String?) ?? '';
    final fim = (sleepSession['hora_fim'] as String?) ?? '';
    return [inicio, fim];
  }

  return duracaoSono;
}

Future<List<int>> buscarExercicioPermanente(
  String userId, {
  DateTime? dia,
}) async {
  List<int> listaWorkouts = [];

  final String dataDoc =
      dia != null
          ? DateFormat('yyyy-MM-dd').format(dia)
          : (await buscarUltimaData()) ?? '';

  final doc =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('dados_permanentes')
          .doc(dataDoc)
          .get();

  if (!doc.exists) return listaWorkouts;

  final dados = doc.data() ?? {};

  final workouts = dados['workouts'];
  if (workouts is Map<String, dynamic>) {
    workouts.forEach((key, value) {
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
  }
  return listaWorkouts;
}
