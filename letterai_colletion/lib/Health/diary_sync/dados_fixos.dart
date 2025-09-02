import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
//import 'package:permission_handler/permission_handler.dart';
//import 'package:carp_serializable/carp_serializable.dart';
import 'package:letterai_colletion/Health/support/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final health = Health();

Future<void> sincronizarDadosFixos() async {
  final now = DateTime.now();
  final endDate = DateTime(now.year, now.month, now.day, now.hour);
  DateTime startDate;

  List<HealthDataType> tiposPorHora =
      (Platform.isAndroid ? dataTypesAndroid : dataTypesIOS)
          .where(
            (type) =>
                type == HealthDataType.STEPS ||
                type == HealthDataType.TOTAL_CALORIES_BURNED ||
                type == HealthDataType.DISTANCE_DELTA,
          )
          .toList();

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('O usuário não está logado');
      return;
    }

    final uuid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uuid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({'criado em': Timestamp.now()});
      debugPrint('Documento de usuário criado com sucesso');
    }

    final dadosDiariosRef = docRef.collection('dados_diarios');

    //Verifica se a coleção está vazia
    final primeiroDoc = await dadosDiariosRef.doc('00').get();
    if (!primeiroDoc.exists) {
      startDate = DateTime(now.year, now.month, now.day);
      debugPrint(
        'Coleção vazia, sincronizando dados entre meia noite e hora atual',
      );
    } else {
      //Verifica se o dia mudou
      final sincronizadoEm = primeiroDoc.get('sincronizado_em') as Timestamp;
      final dataUltimo = sincronizadoEm.toDate();

      if (dataUltimo.day != now.day ||
          dataUltimo.month != now.month ||
          dataUltimo.year != now.year) {
        final batch = FirebaseFirestore.instance.batch();
        final snapshot = await dadosDiariosRef.get();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('Novo dia detectado, coleção limpa');
        startDate = DateTime(now.year, now.month, now.day);
      } else {
        //Buscar última hora salva
        final docs = await dadosDiariosRef.get();
        final horas =
            docs.docs
                .where((d) => d.id != 'total_diario')
                .map((d) => int.tryParse(d.id))
                .whereType<int>()
                .toList();
        final ultimaHora =
            horas.isNotEmpty ? horas.reduce((a, b) => a > b ? a : b) : -1;
        startDate = DateTime(now.year, now.month, now.day, ultimaHora + 1);
        debugPrint(
          'Ultima hora salva: $ultimaHora, sincronizando da hora ${startDate.hour}',
        );
      }
    }

    //Dados por hora
    List<HealthDataPoint> dadosPorHora = await health
        .getHealthIntervalDataFromTypes(
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

    //Salva cada hora
    for (var entrada in dadosAgrupados.entries) {
      final hora = entrada.key;
      final dados = entrada.value;

      List<Map<String, dynamic>> dadosConvertidos =
          dados.map((dado) {
            final valor =
                (dado.value is NumericHealthValue)
                    ? (dado.value as NumericHealthValue).numericValue
                    : double.tryParse(dado.value.toString()) ?? 0.0;

            return {
              'tipo': dado.typeString,
              'valor': valor,
              'fim': dado.dateTo.toIso8601String(),
              'inicio': dado.dateFrom.toIso8601String(),
            };
          }).toList();

      Map<String, double> totaisHora = {};
      for (var dado in dados) {
        final tipo = dado.typeString;
        final valor =
            (dado.value is NumericHealthValue)
                ? (dado.value as NumericHealthValue).numericValue
                : double.tryParse(dado.value.toString()) ?? 0.0;

        totaisHora[tipo] = (totaisHora[tipo] ?? 0) + valor;
        totaisDia[tipo] = (totaisDia[tipo] ?? 0) + valor;
      }

      await dadosDiariosRef.doc(hora).set({
        'dados': dadosConvertidos,
        'totais': totaisHora,
        'sincronizado_em': Timestamp.now(),
      }, SetOptions(merge: true));

      debugPrint('Dados salvos na $hora');
    }

    //Atualizar dados diários com merge
    await dadosDiariosRef.doc("total_diario").set({
      'atividade': {
        'STEPS': FieldValue.increment(totaisDia['STEPS'] ?? 0),
        'TOTAL_CALORIES_BURNED': FieldValue.increment(totaisDia['TOTAL_CALORIES_BURNED'] ?? 0),
        'DISTANCE_DELTA': FieldValue.increment(totaisDia['DISTANCE_DELTA'] ?? 0),
      },
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('Erro ao sincronizar dados: $e');
  }
}
