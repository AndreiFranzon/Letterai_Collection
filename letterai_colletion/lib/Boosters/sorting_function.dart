import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:letterai_colletion/Store/store_page.dart';
import 'package:letterai_colletion/Models/pacote.dart';
import 'package:letterai_colletion/Profile/inventory.dart';

final List<Map<String, dynamic>> cartas = [
  {"id": 1, "raridade": "incomum"},
  {"id": 4, "raridade": "incomum"},
  {"id": 7, "raridade": "incomum"},
  {"id": 10, "raridade": "comum"},
  {"id": 12, "raridade": "comum"},
  {"id": 13, "raridade": "comum"},
  {"id": 15, "raridade": "comum"},
  {"id": 18, "raridade": "comum"},
  {"id": 20, "raridade": "incomum"},
  {"id": 22, "raridade": "incomum"},
  {"id": 24, "raridade": "incomum"},
  {"id": 26, "raridade": "incomum"},
  {"id": 28, "raridade": "incomum"},
  {"id": 31, "raridade": "comum"},
  {"id": 34, "raridade": "incomum"},
  {"id": 37, "raridade": "comum"},
  {"id": 39, "raridade": "raro"},
  {"id": 40, "raridade": "comum"},
  {"id": 43, "raridade": "incomum"},
  {"id": 44, "raridade": "raro"},
  {"id": 45, "raridade": "raro"},
  {"id": 46, "raridade": "epico"},
  {"id": 47, "raridade": "incomum"},
  {"id": 49, "raridade": "epico"},
  {"id": 50, "raridade": "raro"},
  {"id": 51, "raridade": "epico"},
  {"id": 52, "raridade": "epico"},
  {"id": 53, "raridade": "epico"},
  {"id": 54, "raridade": "raro"},
  {"id": 57, "raridade": "lendario"},
  {"id": 58, "raridade": "lendario"},
  {"id": 59, "raridade": "lendario"},
  {"id": 60, "raridade": "mitico"},
];

final Map<String, List<int>> pacotes = {
  //Pacotes do dia
  "1": [1, 4, 10, 18, 24, 40, 46, 47],
  //"1": [1, 4, 10, 13, 28, 37, 52],
  "2": [12, 13, 15, 24, 43, 44, 46, 49],
  "3": [20, 34, 46, 49, 57, 58, 59],
  //Pacotes da noite
  "4": [7, 26, 31, 37, 39, 45, 50],
  "5": [7, 22, 26, 31, 50, 51, 52, 53],
  "6": [22, 28, 39, 45, 50, 54, 60],
};

final Map<String, Map<String, double>> probabilidades = {
  //Pacotes do dia
  "1": {
    "comum": 0.7,
    "incomum": 0.2,
    "raro": 0.08,
    "epico": 0.02,
    "lendario": 0.0,
    "mitico": 0.0,
  },
  "2": {
    "comum": 0.5,
    "incomum": 0.3,
    "raro": 0.12,
    "epico": 0.06,
    "lendario": 0.03,
    "mitico": 0.00,
  },
  "3": {
    "comum": 0.0,
    "incomum": 0.5,
    "raro": 0.3,
    "epico": 0.12,
    "lendario": 0.8,
    "mitico": 0.0,
  },
  //Pacotes da noite
  "4": {
    "comum": 0.7,
    "incomum": 0.2,
    "raro": 0.08,
    "epico": 0.02,
    "lendario": 0.0,
    "mitico": 0.0,
  },
  "5": {
    "comum": 0.5,
    "incomum": 0.3,
    "raro": 0.12,
    "epico": 0.05,
    "lendario": 0.00,
    "mitico": 0.01,
  },
  "6": {
    "comum": 0.0,
    "incomum": 0.47,
    "raro": 0.3,
    "epico": 0.15,
    "lendario": 0.00,
    "mitico": 0.08,
  },
};

Map<String, dynamic> sortearCarta(String pacoteId) {
  final cartasDoPacote = pacotes[pacoteId]!;
  final probs = probabilidades[pacoteId]!;

  //Sorteia as cartas
  List<int> cartasSorteio = [];
  for (var cartaId in cartasDoPacote) {
    final carta = cartas.firstWhere((c) => c["id"] == cartaId);
    final raridade = carta["raridade"] as String;
    final chance = (probs[raridade] ?? 0) * 100; // para escala de 0-100
    final qtd = chance.ceil(); // número de entradas para sorteio proporcional
    cartasSorteio.addAll(List.filled(qtd, cartaId));
  }

  final random = Random();
  final cartaEscolhida = cartasSorteio[random.nextInt(cartasSorteio.length)];

  return cartas.firstWhere((c) => c["id"] == cartaEscolhida);
}

// Sorteia a energia e já salva no Firestore
Future<Map<String, dynamic>> sortearEnergias() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('O usuário não está logado');
    return {
      'energiaId': null,
      'quantidade': 0,
    };
  }

  final userId = user.uid;
  final random = Random();

  int energiaId = random.nextInt(20) + 1; // 1..20
  int quantidade = random.nextInt(3) + 1; // 1..3

  final energiaRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .collection('inventario')
      .doc('itens')
      .collection('energias')
      .doc(energiaId.toString());

  await energiaRef.set({
    'energiaId': energiaId,
    'quantidade': FieldValue.increment(quantidade),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  return {
    'energiaId': energiaId,
    'quantidade': quantidade,
  };
}

//Abrir pacote genérico
Future<Map<String, dynamic>> abrirPacote({
  required Pacote pacote,
  bool decrementarInventario = false, // false = não decrementa, true = decrementa
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('O usuário não está logado');
    return {
      'cartas': [],
      'energia': {'energiaId': null, 'quantidade': 0},
    };
  }

  final userId = user.uid;
  final firestore = FirebaseFirestore.instance;

  // Decrementa a quantidade do pacote se vier do inventário
  if (decrementarInventario) {
    final pacoteRef = firestore
        .collection('usuarios')
        .doc(userId)
        .collection('inventario')
        .doc('itens')
        .collection('pacotes')
        .doc(pacote.id.toString());

    final docAtual = await pacoteRef.get();
    if (docAtual.exists && (docAtual.data()?['quantidade'] ?? 0) > 0) {
      await pacoteRef.update({'quantidade': FieldValue.increment(-1)});
      debugPrint('Pacote ${pacote.id} decrementado no inventário');
    } else {
      debugPrint('Pacote ${pacote.id} não encontrado ou quantidade insuficiente');
      return {
        'cartas': [],
        'energia': {'energiaId': null, 'quantidade': 0},
      };
    }
  }

  List<Map<String, dynamic>> cartasSorteadas = [];
  List<Map<String, dynamic>> cartasParaBatch = [];

  for (int i = 0; i < 3; i++) {
    final cartaSorteada = sortearCarta(pacote.id.toString());
    debugPrint('Carta sorteada: $cartaSorteada');
    final cartaId = cartaSorteada['id'] as int;

    // Busca dados completos da carta
    final cartaDoc = await firestore.collection('cartas').doc(cartaId.toString()).get();
    if (!cartaDoc.exists) {
      debugPrint('Carta $cartaId não encontrada no banco de dados!');
      continue;
    }

    final dadosCarta = cartaDoc.data()!;
    cartasSorteadas.add(dadosCarta); // Sempre adiciona para feedback visual
    debugPrint('Dados da carta adicionada: $dadosCarta');

    // Adiciona campos extras para o inventário principal
    cartasParaBatch.add({
      ...dadosCarta,
      'xp': 0,
      'nivel': 1,
      'pontos_ganhos': 0,
      'obtidaEm': FieldValue.serverTimestamp(),
    });

    // Atualiza coleção auxiliar apenas se ainda não tiver
    final cartaObtidaRef = firestore
        .collection('usuarios')
        .doc(userId)
        .collection('inventario')
        .doc('itens')
        .collection('cartas_obtidas')
        .doc('lista');

    await cartaObtidaRef.set({
      'cartas_obtidas': FieldValue.arrayUnion([cartaId.toString()])
    }, SetOptions(merge: true));
  }

  // Salva todas as cartas sorteadas no inventário principal em batch
  if (cartasParaBatch.isNotEmpty) {
    final batch = firestore.batch();
    for (final carta in cartasParaBatch) {
      final cartaRef = firestore
          .collection('usuarios')
          .doc(userId)
          .collection('inventario')
          .doc('itens')
          .collection('colecao')
          .doc(); // autoId gerado
      batch.set(cartaRef, carta);
    }
    await batch.commit();
  }

  // Sorteia e salva energia
  final energiaSorteada = await sortearEnergias();
  debugPrint('Energia sorteada: $energiaSorteada');
  debugPrint('Cartas sorteadas: $cartasSorteadas');

  return {
    'cartas': cartasSorteadas, // Sempre as 3 cartas sorteadas
    'energia': energiaSorteada,
  };
}
