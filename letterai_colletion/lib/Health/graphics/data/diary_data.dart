import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> carregarDadosDiarios() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('O usuário não está logado');
    return;
  }

  final userId = user.uid;
}

Future<List<int>> buscarPassosDiarios (String userId) async {
  List<int> passos = [];

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('dados_diarios')
      .doc(hora)
      .get();

    if (doc.exists) {
      final dados = doc.data()?['dados'] as List<dynamic>? ?? [];

      final step = dados.firstWhere(
        (element) => element['tipo'] == 'STEPS',
        orElse: () => {'valor': 0});
      passos.add(step['valor'] ?? 0);
    } else {
      passos.add(0);
    }
  }

  return passos;
}

Future<List<int>> buscarCaloriasDiarias (String userId) async {
  List<int> caloriasDiarias = [];

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('dados_diarios')
      .doc(hora)
      .get();

    if (doc.exists) {
      final dados = doc.data()?['dados'] as List<dynamic>? ?? [];

      final calories = dados.firstWhere(
        (element) => element['tipo'] == 'TOTAL_CALORIES_BURNED',
        orElse: () => {'valor': 0});
      caloriasDiarias.add((calories['valor'] as num?)?.toInt() ?? 0);
    } else {
      caloriasDiarias.add(0);
    }
  }

  return caloriasDiarias;
}

Future<List<int>> buscarDistanciaDiaria (String userId) async {
  List<int> distanciaDiaria = [];

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('dados_diarios')
      .doc(hora)
      .get();

    if (doc.exists) {
      final dados = doc.data()?['dados'] as List<dynamic>? ?? [];

      final distance = dados.firstWhere(
        (element) => element['tipo'] == 'DISTANCE_DELTA',
        orElse: () => {'valor': 0});
      distanciaDiaria.add((distance['valor'] as num?)?.toInt() ?? 0);
    } else {
      distanciaDiaria.add(0);
    }
  }

  return distanciaDiaria;
}
