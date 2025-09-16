import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

String supportCards(Map<String, dynamic> cardData) {
  if (cardData.containsKey('evolui') && cardData['evolui'] != null) {
    return "Esta carta pode evoluir para: ${cardData['evolui']}";
  } else {
    return ""; // Retorna vazio se não puder evoluir
  }
}

String getEnergyImage(int tipo1) {
  return 'assets/energies/$tipo1.png';
}

String getEvoImage(int evolui) {
  return 'assets/front_cards/$evolui.png';
}

Future<int> getInventoryEnergy(dynamic tipo) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 0;

  final doc =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('inventario')
          .doc('itens')
          .collection('energias')
          .doc(tipo.toString())
          .get();

  if (doc.exists && doc.data() != null) {
    return doc.data()!['quantidade'] ?? 0;
  }
  return 0;
}

Future<void> evolveCard(
  Map<String, dynamic> cardData, {
  int energyRequired = 5,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final tipoEnergia = cardData['tipo1'].toString();
  final currentEnergy = await getInventoryEnergy(tipoEnergia);

  if (currentEnergy < energyRequired) {
    return;
  }

  final newEnergy = currentEnergy - energyRequired;
  await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .collection('inventario')
      .doc('itens')
      .collection('energias')
      .doc(tipoEnergia)
      .update({'quantidade': newEnergy});

  final nextCardId = cardData['evolui'].toString();

  final nextCardDoc =
      await FirebaseFirestore.instance
          .collection('cartas')
          .doc(nextCardId)
          .get();

  if (!nextCardDoc.exists || nextCardDoc.data() == null) {
    return;
  }

  final nextCardData = nextCardDoc.data()!;

  cardData['imagem'] = nextCardData['imagem'];

  if (nextCardData['evolui'] != null) {
    cardData['evolui'] = nextCardData['evolui'];
  } else {
    cardData.remove('evolui');
  }

  final stats = ['vida', 'ataque', 'defesa', 'velocidade', 'magia', 'sorte'];
  for (var stat in stats) {
    cardData[stat] = (cardData[stat] ?? 0) + 9;
  }

  await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .collection('inventario')
      .doc('itens')
      .collection('colecao')
      .doc(cardData['id'].toString())
      .set(cardData);

  final cartaAtivaDoc =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('inventario')
          .doc('itens')
          .collection('carta_ativa')
          .doc('selecionada')
          .get();

  if (cartaAtivaDoc.exists && cartaAtivaDoc.data() != null) {
    final ativaCarta = cartaAtivaDoc.data()!;
    if (ativaCarta['id'].toString() == cardData['id'].toString()) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('inventario')
          .doc('itens')
          .collection('carta_ativa')
          .doc('selecionada')
          .update({'imagem': cardData['imagem']});
    }
  }
}
