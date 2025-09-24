import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> inicializarEstatisticas(User user) async {
  final estatisticasRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .collection('estatisticas');

  final snapshot = await estatisticasRef.limit(1).get();

  // 🔹 Se a coleção não tem nenhum documento, inicializa do zero
  if (snapshot.docs.isEmpty) {
    print("Coleção estatisticas não encontrada, criando...");

    await estatisticasRef.doc('nivel').set({
      'nivel': 1,
      'xp': 0,
    });

    await estatisticasRef.doc('pontos_amarelos').set({
      'pontos': 0,
    });

    await estatisticasRef.doc('pontos_roxos').set({
      'pontos': 0,
    });

    print("Estatísticas criadas com sucesso!");
  } else {
    print("Coleção estatisticas já existe, não foi necessário recriar.");
  }
}

Future<bool> verificarApelido(User user) async {
  final docRef = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(user.uid)
      .collection("estatisticas")
      .doc("dados_pessoais");

  final docSnap = await docRef.get();

  if (!docSnap.exists) return false;

  final dados = docSnap.data();
  if (dados == null || dados["apelido"] == null) {
    return false;
  }

  return true;
}

class FriendCode {
  static String gerarFriendCode(String uid) {
    final posicoes = [4, 13, 1, 16, 9, 8, 12, 0];
    final codeChars = posicoes.map((p) {
      if (p < uid.length) {
        final c = uid[p];
        return c.toUpperCase();
      }
      return 'X';
    }).join();

    return codeChars;
  }

  static Future<void> friendCode(User user) async {
    final friendDoc = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('estatisticas')
        .doc('codigo_amigo');

    final snapshot = await friendDoc.get();

    String code;
    if (!snapshot.exists) {
      code = gerarFriendCode(user.uid);
      await friendDoc.set({'code': code});
    } else {
      code = snapshot.data()?['code'] ?? gerarFriendCode(user.uid);
      print("Friend code já existe: $code");
    }

    // 🔹 Salva também na coleção global friend_codes
    final globalDoc = FirebaseFirestore.instance
        .collection('codigo_amigo')
        .doc(code);

    await globalDoc.set({
      'uid': user.uid,
      'code': code,
    });
  }

}

