import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letterai_colletion/Login/login_support.dart';

class FriendsSupport {
  static Future<String> carregarFriendCode(String uid) async {
    final docRef = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("estatisticas")
        .doc("friend_code");

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      return snapshot.data()?['code'] ?? "";
    } else {
      // Se não existir, cria um novo código
      final code = FriendCode.gerarFriendCode(uid);
      await docRef.set({'code': code});
      return code;
    }
  }

  static Future<String?> buscarFriendCode(String code) async {
    final doc =
        await FirebaseFirestore.instance
            .collection("codigo_amigo")
            .doc(code)
            .get();

    if (doc.exists) {
      return doc.data()?['uid']; // Retorna o UID do usuário dono do código
    } else {
      return null; // Código não encontrado
    }
  }

  static Future<void> enviarPedidoAmizade(
    String meuUid,
    String friendUid,
  ) async {
    final amigosRefMeu = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(meuUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('pendentes')
        .doc(friendUid);

    final amigosRefFriend = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(friendUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('recebidas')
        .doc(meuUid);

    // Atualiza ambos documentos
    await amigosRefMeu.set({'status': 'enviado'}, SetOptions(merge: true));
    await amigosRefFriend.set({'status': 'pendente'}, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> buscarPedidosRecebidos(
    String meuUid,
  ) async {
    final pedidosRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(meuUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('recebidas');

    final querySnapshot = await pedidosRef.get();

    List<Map<String, dynamic>> pedidos = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      pedidos.add({
        'uuid': doc.id, // UUID de quem enviou
        'status': data['status'] ?? 'pendente',
      });
    }

    return pedidos;
  }

  static Future<void> aceitarPedido(String meuUid, String friendUid) async {
    final amigosRefMeuRecebidas = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(meuUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('recebidas')
        .doc(friendUid);

    final amigosRefMeuAceitas = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(meuUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('aceitas')
        .doc(friendUid);

    final amigosRefFriendPendentes = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(friendUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('pendentes')
        .doc(meuUid);

    final amigosRefFriendAceitas = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(friendUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('aceitas')
        .doc(meuUid);

    // Pega o status atual do pedido
    final snapshot = await amigosRefMeuRecebidas.get();
    if (!snapshot.exists) return; // não existe pedido

    // Copia o status para "aceitas" do usuário logado
    await amigosRefMeuAceitas.set({
      'status': 'aceito',
    }, SetOptions(merge: true));
    await amigosRefMeuRecebidas.delete(); // remove de "recebidas"

    // Atualiza o status no outro usuário
    await amigosRefFriendAceitas.set({
      'status': 'aceito',
    }, SetOptions(merge: true));
    await amigosRefFriendPendentes.delete(); // remove de "pendentes"
  }

  static Future<void> recusarPedido(String meuUid, String friendUid) async {
    final amigosRefMeuRecebidas = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(meuUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('recebidas')
        .doc(friendUid);

    final amigosRefMeuAceitas = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(meuUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('recusadas')
        .doc(friendUid);

    final amigosRefFriendPendentes = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(friendUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('pendentes')
        .doc(meuUid);

    final amigosRefFriendAceitas = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(friendUid)
        .collection('estatisticas')
        .doc('amizades')
        .collection('recusadas')
        .doc(meuUid);

    // Pega o status atual do pedido
    final snapshot = await amigosRefMeuRecebidas.get();
    if (!snapshot.exists) return; // não existe pedido

    await amigosRefMeuAceitas.set({
      'status': 'recusado',
    }, SetOptions(merge: true));
    await amigosRefMeuRecebidas.delete(); // remove de "recebidas"

    // Atualiza o status no outro usuário
    await amigosRefFriendAceitas.set({
      'status': 'recusado',
    }, SetOptions(merge: true));
    await amigosRefFriendPendentes.delete(); // remove de "pendentes"
  }

  static Future<List<String>> listarAmigos(String meuUid) async {
  final amigosRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(meuUid)
      .collection('estatisticas')
      .doc('amizades')
      .collection('aceitas');

  final snapshot = await amigosRef.get();

  return snapshot.docs.map((doc) => doc.id).toList();
}

static Future<void> removerAmigo(String meuUid, String friendUid) async {
  final amigosRefMeu = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(meuUid)
      .collection('estatisticas')
      .doc('amizades')
      .collection('aceitas')
      .doc(friendUid);

  final amigosRefFriend = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(friendUid)
      .collection('estatisticas')
      .doc('amizades')
      .collection('aceitas')
      .doc(meuUid);

  // Remove amizade dos dois lados
  await amigosRefMeu.delete();
  await amigosRefFriend.delete();
}

}
