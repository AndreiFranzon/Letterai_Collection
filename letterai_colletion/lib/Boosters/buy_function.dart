import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:letterai_colletion/Store/store_page.dart';
import 'package:letterai_colletion/Models/pacote.dart';

//Faz a compra do pacote
class BuyFunction {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> buyBooster(
    BuildContext context,
    String userId,
    Pacote pacote,
  ) async {
    try {
      final statsRef = _firestore
          .collection("usuarios")
          .doc(userId)
          .collection("estatisticas");
      final String docName =
          pacote.moeda == "yellow" ? "pontos_amarelos" : "pontos_roxos";
      final docSnap = await statsRef.doc(docName).get();

      if (!docSnap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível carregar os pontos do usuário"),
          ),
        );
        return false;
      }

      final data = docSnap.data();
      int pontos = (data?["pontos"] as num?)?.toInt() ?? 0;

      if (pontos < pacote.valor) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Saldo insuficiente!")));
        return false;
      }

      // Atualiza os pontos
      await statsRef.doc(docName).update({"pontos": pontos - pacote.valor});

      return true; // compra realizada
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao realizar a compra: $e")));
      return false;
    }
  }
}

//Salva o pacote
class InventoryFunction {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePackage(String userId, Pacote pacote, BuildContext context) async {
  try {
    final inventarioRef = _firestore
        .collection("usuarios")
        .doc(userId)
        .collection("inventario")
        .doc("itens")
        .collection("pacotes")
        .doc(pacote.id.toString());

    await inventarioRef.set({
      "nome": pacote.nome,
      "id": pacote.id,
      "quantidade": FieldValue.increment(1),
      "adquirido_em": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // aqui você pode simplesmente fechar o diálogo
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

  } catch (e) {
    // apenas loga o erro no console
    debugPrint("Erro ao salvar pacote: $e");
 
  }
}

}
