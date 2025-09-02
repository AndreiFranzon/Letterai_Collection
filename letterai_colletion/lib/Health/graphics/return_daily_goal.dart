//tela onde eu carrego as métricas diárias relacionadas apenas à saúde
import 'package:cloud_firestore/cloud_firestore.dart';

class MetasUsuario {
  final int passos;
  final int calorias;
  final double distancia;
  final double sono;
  final double exercicios;
  final bool temMetas;

  MetasUsuario({
    required this.passos,
    required this.calorias,
    required this.distancia,
    required this.sono,
    required this.exercicios,
    required this.temMetas,
  });

  factory MetasUsuario.fromMap(Map<String, dynamic> map) {
  return MetasUsuario(
    passos: (map['metaPassos'] as num?)?.toInt() ?? 0,
    calorias: (map['metaCalorias'] as num?)?.toInt() ?? 0,
    distancia: (map['metaDistancia'] as num?)?.toDouble() ?? 0.0,
    sono: (map['metaSono'] as num?)?.toDouble() ?? 0.0,
    exercicios: (map['metaExercicios'] as num?)?.toDouble() ?? 0.0,
    temMetas: true,
  );
}
}

Future<MetasUsuario> buscarMetasUsuario(String uid) async {
  print("Buscando metricas do usuario $uid");
  try {
    final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .collection('estatisticas')
      .doc('dados_pessoais')
      .get();
    
    final data = doc.data() as Map<String, dynamic>?;

      print("documento recebido $data");

     if (data != null) {
      return MetasUsuario.fromMap(data);
    } else {
      // Retorna objeto com valores padrão
      return MetasUsuario(
        passos: 0,
        calorias: 0,
        distancia: 0,
        sono: 0,
        exercicios: 0,
        temMetas: false,
      );
    }
  } catch (e) {
    print("Erro ao buscar metas do usuário: $e");
    return MetasUsuario(
        passos: 0,
        calorias: 0,
        distancia: 0,
        sono: 0,
        exercicios: 0,
        temMetas: true,
      );
  }
}


