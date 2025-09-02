import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:letterai_colletion/Health/graphics/data/diary_data.dart';
import 'package:letterai_colletion/Database_Support/sync_functions.dart';
class dadosDiariosProvider with ChangeNotifier {
  bool carregando = true;

  //Dados hora a hora
  List<int> passosHora = [];
  List<int> caloriasHora = [];
  List<int> distanciaHora = [];
  List<String> sessoesSono = [];
  List<int> sessoesExercicio = [];

  //Totais
  int totalPassos = 0;
  int totalCalorias = 0;
  int totalDistancia = 0;
  double totalSono = 0;
  double totalExercicio = 0;

  // cache dos exercicios
  Future<void> carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    carregando = true;
    notifyListeners();

    try {
      await sincronizarTudo(sync: (value){
        sync = value;
        notifyListeners();
        
      });
      //Passos
      passosHora = await buscarPassosDiarios(userId);
      totalPassos = await buscarTotalMetricasDiarias(userId, "STEPS");

      //Calorias
      caloriasHora = await buscarCaloriasDiarias(userId);
      totalCalorias = await buscarTotalMetricasDiarias(userId, "TOTAL_CALORIES_BURNED");

      //Distancia
      distanciaHora = await buscarDistanciaDiaria(userId);
      totalDistancia = await buscarTotalMetricasDiarias(userId, "DISTANCE_DELTA");

      //Sono
      sessoesSono = await buscarSonoDiario(userId);
      totalSono = await buscarTotalSonoDiario(userId);

      //Exercicios
      sessoesExercicio = await buscarExercicioDiario(userId);
      totalExercicio = await buscarTotalExercicioDiario(userId);

    }catch (e) {
      debugPrint("Erro ao carregar dados diários: $e");
    }
    
    carregando = false;
    notifyListeners();
  }
}