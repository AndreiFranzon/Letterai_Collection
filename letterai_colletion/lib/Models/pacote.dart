class Pacote {
  final int id;
  final String nome;
  final String imagem;
  final int valor;       // valor do pacote
  final String moeda;    // "purple" ou "yellow"

  Pacote({
    required this.id,
    required this.nome,
    required this.imagem,
    required this.valor,
    required this.moeda,
  });

  factory Pacote.fromMap(Map<String, dynamic> map) {
    return Pacote(
      id: map['id'] ?? 0,
      nome: map['nome'] ?? '',
      imagem: map['imagem'] ?? '',
      valor: map['valor'] ?? 0,
      moeda: map['moeda'] ?? 'yellow',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'imagem': imagem,
      'valor': valor,
      'moeda': moeda,
    };
  }
}