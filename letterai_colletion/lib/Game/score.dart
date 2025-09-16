import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:letterai_colletion/Health/graphics/data/perm_data.dart';

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

Future<Map<String, dynamic>> buscarMetricas(DateTime diaAlvo) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('Usuário não está logado');
    return {
       "passos": 0,
      "calorias": 0,
      "distancia": 0,
      "exercicio": 0,
      "sono": 0,
    };
  }

  final String userId = user.uid;
  String dataDoc = DateFormat('yyyy-MM-dd').format(diaAlvo);
  
  try {
    //Busca os dados
    final passos = await buscarTotalMetricas(userId, "STEPS", dataDoc);
    final calorias = await buscarTotalMetricas(userId, "TOTAL_CALORIES_BURNED", dataDoc);
    final distancia = await buscarTotalMetricas(userId, "DISTANCE_DELTA", dataDoc);
    final exercicio = await buscarTotalExercicio(userId, dataDoc);
    final sono = await buscarTotalSono(userId, dataDoc);

    return{
      "passos": passos,
      "calorias": calorias,
      "distancia": distancia,
      "exercicio": exercicio,
      "sono": sono,
    };
  } catch (e) {
    debugPrint("Erro ao buscar métricas do dia $dataDoc");
    return {
      "passos": 0,
      "calorias": 0,
      "distancia": 0,
      "exercicio": 0,
      "sono": 0,
    };
  }
}

Future<int> calcularPontosAmarelos(DateTime diaAlvo) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return 0;
  }

  final String userId = user.uid;
  String dataDoc = DateFormat('yyyy-MM-dd').format(diaAlvo);


  final metricas = await buscarMetricas(diaAlvo);

  final passos = metricas['passos'] ?? 0;
  final calorias = metricas['calorias'] ?? 0;
  final distancia = metricas['distancia'] ?? 0;
  final exercicio = metricas['exercicio'] ?? 0;

  int pontuacaoBase = (passos ~/ 200) + (calorias ~/ 200) + (distancia~/200);
  int pontuacaoFinal = (pontuacaoBase * (1 + exercicio)).round();

  debugPrint("Pontos amarelos: $pontuacaoFinal");

  await FirebaseFirestore.instance
    .collection('usuarios')
    .doc(userId)
    .collection('estatisticas')
    .doc('pontos_amarelos')
    .set({
      'data': dataDoc,
      'pontos': FieldValue.increment(pontuacaoFinal),
    }, SetOptions(merge: true));
  
  return pontuacaoFinal;
}

Future<int> calcularPontosRoxos(DateTime diaAlvo) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return 0;
  }

  final String userId = user.uid;
  String dataDoc = DateFormat('yyyy-MM-dd').format(diaAlvo);

  final metricas = await buscarMetricas(diaAlvo);
  final sono = metricas['sono'] ?? 0.0;

  double pontuacaoBase = sono * 20;

  if (sono == 8) {
    pontuacaoBase *= 2;
  } else {
    double diferenca = (sono - 8).abs();
    pontuacaoBase *= (1 - 0.1 * diferenca);
    if (pontuacaoBase < 0) pontuacaoBase = 0;
  }

  int pontuacaoFinal = pontuacaoBase.round();

  debugPrint("Pontos roxos: $pontuacaoFinal");

  await FirebaseFirestore.instance
    .collection('usuarios')
    .doc(userId)
    .collection('estatisticas')
    .doc('pontos_roxos')
    .set({
      'data': dataDoc,
      'pontos': FieldValue.increment(pontuacaoFinal),
    }, SetOptions(merge: true));

  return pontuacaoFinal;
}