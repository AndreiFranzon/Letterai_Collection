import 'dart:async';
import 'dart:io';

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

  final userId = user.uid;
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

Future<List<int>> buscarPassosPermanentes(String userId) async {
  List<int> passos = [];
  final ultimaData = await buscarUltimaData();

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    if (ultimaData != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('dados_permanentes')
              .doc(ultimaData)
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

Future<List<int>> buscarCaloriasPermanentes(String userId) async {
  List<int> calorias = [];
  final ultimaData = await buscarUltimaData();

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    if (ultimaData != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('dados_permanentes')
              .doc(ultimaData)
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

Future<List<int>> buscarDistanciaPermanente(String userId) async {
  List<int> distanciaDiaria = [];
  final ultimaData = await buscarUltimaData();

  for (int i = 0; i < 24; i++) {
    final hora = i.toString().padLeft(2, '0');

    if (ultimaData != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('dados_permanentes')
              .doc(ultimaData)
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
