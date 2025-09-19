import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PontosProvider with ChangeNotifier {
  int pontosAmarelos = 0;
  int pontosRoxos = 0;
  int nivel = 1;
  int xp = 0;
  bool carregando = true;

  StreamSubscription? _subAmarelos;
  StreamSubscription? _subRoxos;
  StreamSubscription? _subNivel;

  void iniciarListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    final estatisticasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('estatisticas');

        //Captura os pontos amarelos
      _subAmarelos = estatisticasRef.doc('pontos_amarelos').snapshots().listen((doc) {
        if (doc.exists) {
          pontosAmarelos = doc.data()?['pontos'] ?? 0;
          carregando = false;
          notifyListeners();
        }
      });

      _subRoxos = estatisticasRef.doc('pontos_roxos').snapshots().listen((doc) {
        if (doc.exists) {
          pontosRoxos = doc.data()?['pontos'] ?? 0;
          carregando = false;
          notifyListeners();
        }
      });  

      _subNivel = estatisticasRef.doc('nivel').snapshots().listen((doc) {
        if (doc.exists) {
          nivel = doc.data()?['nivel'] ?? 1;
          xp = doc.data()?['xp'] ?? 0;
          carregando = false;
          notifyListeners();
        }
      });
  }

  @override
  void dispose() {
    _subAmarelos?.cancel();
    _subRoxos?.cancel();
    _subNivel?.cancel();
    super.dispose();
  }
}
