import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:letterai_colletion/Health/support/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final health = Health();

Future<void> sincronizarDadosFixosPermantentes (DateTime diaAlvo) async {
    final startDate = DateTime(diaAlvo.year, diaAlvo.month, diaAlvo.day,  0, 0, 0);
    final endDate = DateTime(diaAlvo.year, diaAlvo.month, diaAlvo.day, 23, 59, 59);

    List<HealthDataType> tiposPorHora = (Platform.isAndroid ? dataTypesAndroid : dataTypesIOS)
      .where((type) =>
      type == HealthDataType.STEPS ||
      type == HealthDataType.TOTAL_CALORIES_BURNED ||
      type == HealthDataType.DISTANCE_DELTA)
    .toList();


    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('O usuário não está logado');
        return;
      }

      final uuid = user.uid;
      final dataFormatada = DateFormat('yyyy-MM-dd').format(diaAlvo);

      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uuid).collection('dados_permanentes').doc(dataFormatada);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({'criado em': Timestamp.now()});
        debugPrint('Documento de usuário criado com sucesso');
      } else {
        debugPrint('Documento do usuário já existe');
      }

      final dadosDiariosRef = docRef.collection('dados_diarios');

      //Dados por hora
      List<HealthDataPoint> dadosPorHora = await health.getHealthIntervalDataFromTypes(
        startDate: startDate, 
        endDate: endDate, 
        types: tiposPorHora, 
        interval: 3600,
      );

      Map<String, List<HealthDataPoint>> dadosAgrupados = {};
      Map<String, double> totaisDia = {};

      for (var data in dadosPorHora) {
        final hora = data.dateFrom.hour.toString().padLeft(2, '0');
        dadosAgrupados.putIfAbsent(hora, () => []);
        dadosAgrupados[hora]!.add(data);
      }

      for (var entrada in dadosAgrupados.entries) {
        final hora = entrada.key;
        final dados = entrada.value;

        List<Map<String, dynamic>> dadosConvertidos = dados.map((dado) {
          final valor = (dado.value is NumericHealthValue)
            ? (dado.value as NumericHealthValue).numericValue
            : double.tryParse(dado.value.toString()) ?? 0.0;

          totaisDia[dado.typeString] = (totaisDia[dado.typeString] ?? 0) + valor;

          return {
            'tipo': dado.typeString,
            'valor': valor,
            'fim': dado.dateTo.toIso8601String(),
            'inicio': dado.dateFrom.toIso8601String(),
          };
        }).toList();

        await dadosDiariosRef.doc(hora).set({
          'dados': dadosConvertidos,
          'sincronizado_em': Timestamp.now(),
        });

        debugPrint('Dados salvos na hora $hora');
      }

      final totalDiarioRef = docRef.collection('total_diario').doc('totais');
      await totalDiarioRef.set({
        'totais_atividade': totaisDia,
        'sincronizado_em': Timestamp.now(),
      });

      debugPrint('Total diário de dados fixos permanentes salvo');
    } catch (e) {
      debugPrint('Erro ao sincronizar dados: $e');
    }
  }