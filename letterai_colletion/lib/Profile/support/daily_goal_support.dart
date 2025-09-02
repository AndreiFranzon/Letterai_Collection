//Tela onde salvo as metas e carrego elas na tela para novas alterações
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> salvarDadosPessoais({
  required String userId,
  required int metaPassos,
  required int metaCalorias,
  required double metaDistancia,
  required double metaSono,
  required double metaExercicios,
  required double altura,
  required int genero,
  required DateTime dataNascimento,
  required double peso,
}) async {
  final docRef = FirebaseFirestore.instance
    .collection('usuarios')
    .doc(userId)
    .collection('estatisticas')
    .doc('dados_pessoais');

  await docRef.set({
    'metaPassos': metaPassos,
    'metaCalorias': metaCalorias,
    'metaDistancia': metaDistancia,
    'metaSono': metaSono,
    'metaExercicios': metaExercicios,
    'altura': altura,
    'genero': genero,
    'dataNascimento': dataNascimento.toIso8601String(),
    'peso': peso,
  }, SetOptions(merge: true));
}

class DadosPessoais {
  final int metaPassos;
  final int metaCalorias;
  final double metaDistancia;
  final double metaSono;
  final double metaExercicios;
  final double altura;
  final int genero;
  final DateTime dataNascimento;
  final double peso;

  DadosPessoais({
    required this.metaPassos,
    required this.metaCalorias,
    required this.metaDistancia,
    required this.metaSono,
    required this.metaExercicios,
    required this.altura,
    required this.genero,
    required this.dataNascimento,
    required this.peso,
  });

  factory DadosPessoais.fromFirestore(Map<String, dynamic> data) {
  return DadosPessoais(
    metaPassos: data['metaPassos'],
    metaCalorias: data['metaCalorias'],
    metaDistancia: (data['metaDistancia']).toDouble(),
    metaSono: (data['metaSono']).toDouble(),
    metaExercicios: (data['metaExercicios']).toDouble(),
    altura: (data['altura']).toDouble(),
    genero: data['genero'],
    dataNascimento: DateTime.parse(data['dataNascimento']),
    peso: (data['peso']).toDouble(),
  );
}
}

Future<DadosPessoais> carregarDadosPessoais(String userId) async {
  final docRef = FirebaseFirestore.instance
    .collection('usuarios')
    .doc(userId)
    .collection('estatisticas')
    .doc('dados_pessoais');

  final snapshot = await docRef.get();

  if (snapshot.exists) {
    return DadosPessoais.fromFirestore(snapshot.data() as Map<String, dynamic>);
  } else {
    return DadosPessoais(
      metaPassos: 10000, 
      metaCalorias: 500, 
      metaDistancia: 5000.0, 
      metaSono: 8.0, 
      metaExercicios: 1.0, 
      altura: 0.0, 
      genero: 0, 
      dataNascimento: DateTime(0000, 01, 01), 
      peso: 0.0,
      );
  }
}