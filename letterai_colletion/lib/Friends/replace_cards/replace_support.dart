import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> salvarPropostaCompleta({
  required String amigoUid,
  required List<Map<String, dynamic>> cartasSelecionadas,
  required String mensagem,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // --- Documento do remetente (minha coleção de enviadas) ---
  final propostaEnviadaDoc = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(uid)
      .collection("estatisticas")
      .doc("propostas")
      .collection("enviadas")
      .doc(amigoUid); // UUID do amigo no nome do doc

  // --- Documento do destinatário (coleção de recebidas do amigo) ---
  final propostaRecebidaDoc = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(amigoUid)
      .collection("estatisticas")
      .doc("propostas")
      .collection("recebidas")
      .doc(uid); // UID do remetente no nome do doc

// Monta o mapa das cartas com todos os campos
final Map<String, dynamic> cartasMap = {};
for (var carta in cartasSelecionadas) {
  final cartaId = carta['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

  final cartaMap = {
    "id_original": carta['id'],
    "ataque": carta['ataque'],
    "defesa": carta['defesa'],
    "imagem": carta['imagem'],
    "magia": carta['magia'],
    "nivel": carta['nivel'],
    "num": carta['num'],
    "obtidaEm": carta['obtidaEm'],
    "pontos_ganhos": carta['pontos_ganhos'],
    "sorte": carta['sorte'],
    "tipo1": carta['tipo1'],
    "velocidade": carta['velocidade'],
    "vida": carta['vida'],
    "xp": carta['xp'],
  };

  // ✅ Adiciona 'tipo2' apenas se existir
  if (carta.containsKey('tipo2')) {
    cartaMap['tipo2'] = carta['tipo2'];
  }

  // ✅ Adiciona 'evolui' apenas se existir
  if (carta.containsKey('evolui')) {
    cartaMap['evolui'] = carta['evolui'];
  }

  cartasMap[cartaId] = cartaMap;
}

  final propostaData = {
    "destinatarioUid": amigoUid,
    "remetenteUid": uid,
    "cartas": cartasMap,
    "mensagemRemetente": mensagem,
    "criadoEm": FieldValue.serverTimestamp(),
  };

  // Salva em ambos os bancos
  await Future.wait([
    propostaEnviadaDoc.set(propostaData),
    propostaRecebidaDoc.set(propostaData),
  ]);

  print("Proposta salva com sucesso para $amigoUid e no meu banco!");
}

Future<void> enviarContraProposta({
  required String amigoUid,
  required List<Map<String, dynamic>> cartasSelecionadas,
  required String mensagem,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // --- Documento do remetente (minha coleção de contrapropostas enviadas) ---
  final contraPropostaEnviadaDoc = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(uid)
      .collection("estatisticas")
      .doc("propostas")
      .collection("contraproposta_enviada")
      .doc(amigoUid);

  // --- Documento do destinatário (coleção de contrapropostas recebidas do amigo) ---
  final contraPropostaRecebidaDoc = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(amigoUid)
      .collection("estatisticas")
      .doc("propostas")
      .collection("contraproposta_recebida")
      .doc(uid);

  // Monta o mapa das cartas com todos os campos
final Map<String, dynamic> cartasMap = {};
for (var carta in cartasSelecionadas) {
  final cartaId = carta['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

  final cartaMap = {
    "id_original": carta['id'],
    "ataque": carta['ataque'],
    "defesa": carta['defesa'],
    "imagem": carta['imagem'],
    "magia": carta['magia'],
    "nivel": carta['nivel'],
    "num": carta['num'],
    "obtidaEm": carta['obtidaEm'],
    "pontos_ganhos": carta['pontos_ganhos'],
    "sorte": carta['sorte'],
    "tipo1": carta['tipo1'],
    "velocidade": carta['velocidade'],
    "vida": carta['vida'],
    "xp": carta['xp'],
  };

  // ✅ Adiciona 'tipo2' apenas se existir
  if (carta.containsKey('tipo2')) {
    cartaMap['tipo2'] = carta['tipo2'];
  }

  // ✅ Adiciona 'evolui' apenas se existir
  if (carta.containsKey('evolui')) {
    cartaMap['evolui'] = carta['evolui'];
  }

  cartasMap[cartaId] = cartaMap;
}

  final contraPropostaData = {
    "destinatarioUid": amigoUid,
    "remetenteUid": uid,
    "cartas": cartasMap,
    "mensagemRemetente": mensagem,
    "criadoEm": FieldValue.serverTimestamp(),
  };

  // Salva em ambos os bancos
  await Future.wait([
    contraPropostaEnviadaDoc.set(contraPropostaData),
    contraPropostaRecebidaDoc.set(contraPropostaData),
  ]);

  print("Contra-proposta enviada com sucesso para $amigoUid e registrada no meu banco!");
}

Future<void> confirmarTroca(String amigoUid) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final firestore = FirebaseFirestore.instance;

  try {
    // ------------------------
    // 1️⃣ Meu banco (quem aceita)
    // ------------------------
    // Pegar cartas enviadas
    final enviadasDoc = await firestore
        .collection("usuarios")
        .doc(uid)
        .collection("estatisticas")
        .doc("propostas")
        .collection("enviadas")
        .doc(amigoUid)
        .get();

    if (enviadasDoc.exists) {
      final cartasEnviadas =
          Map<String, dynamic>.from(enviadasDoc.data()!['cartas'] ?? {});

      // Verificar carta ativa e removê-la se for enviada
      final cartaAtivaDoc = await firestore
          .collection("usuarios")
          .doc(uid)
          .collection("inventario")
          .doc("itens")
          .collection("carta_ativa")
          .doc("selecionada")
          .get();

      if (cartaAtivaDoc.exists) {
        final cartaAtivaData = cartaAtivaDoc.data();
        final idCartaAtiva = cartaAtivaData?['id']?.toString();
        if (idCartaAtiva != null && cartasEnviadas.containsKey(idCartaAtiva)) {
          await firestore
              .collection("usuarios")
              .doc(uid)
              .collection("inventario")
              .doc("itens")
              .collection("carta_ativa")
              .doc("selecionada")
              .delete();
          print("Carta ativa removida por estar sendo enviada na troca.");
        }
      }

      // Remover cada carta do inventário
      for (var cartaId in cartasEnviadas.keys) {
        await firestore
            .collection("usuarios")
            .doc(uid)
            .collection("inventario")
            .doc("itens")
            .collection("colecao")
            .doc(cartaId)
            .delete();
      }

      // Remover registro de enviadas
      await firestore
          .collection("usuarios")
          .doc(uid)
          .collection("estatisticas")
          .doc("propostas")
          .collection("enviadas")
          .doc(amigoUid)
          .delete();
    }

    // ------------------------
    // Recebo a contraproposta (meu lado) -> adicionar cartas e atualizar cartas_obtidas
    // ------------------------
    final contrapropostaDoc = await firestore
        .collection("usuarios")
        .doc(uid)
        .collection("estatisticas")
        .doc("propostas")
        .collection("contraproposta_recebida")
        .doc(amigoUid)
        .get();

    if (contrapropostaDoc.exists) {
      final cartasReceber =
          Map<String, dynamic>.from(contrapropostaDoc.data()!['cartas'] ?? {});

      // Referência ao doc cartas_obtidas do meu usuário
      final cartasObtidasRef = firestore
          .collection("usuarios")
          .doc(uid)
          .collection("inventario")
          .doc("itens")
          .collection("cartas_obtidas")
          .doc("lista");

      final cartasObtidasDoc = await cartasObtidasRef.get();

      // Normaliza lista atual para Set<String>
      final Set<String> obtidasSet = {};
      if (cartasObtidasDoc.exists) {
        final raw = cartasObtidasDoc.data()?['cartas_obtidas'] ?? [];
        for (var e in List.from(raw)) {
          if (e != null) obtidasSet.add(e.toString());
        }
      }

      final List<String> novosNumsParaAdicionar = [];

      // Adicionar cartas ao inventário e coletar nums novos
      for (var cartaEntry in cartasReceber.entries) {
        final cartaId = cartaEntry.key;
        final cartaData = Map<String, dynamic>.from(cartaEntry.value);

        // Salvar no inventário do meu usuário
        await firestore
            .collection("usuarios")
            .doc(uid)
            .collection("inventario")
            .doc("itens")
            .collection("colecao")
            .doc(cartaId)
            .set(cartaData);

        // Normaliza 'num' para string e verifica se é novo
        final numCarta = cartaData['num']?.toString();
        if (numCarta != null && !obtidasSet.contains(numCarta)) {
          novosNumsParaAdicionar.add(numCarta);
          obtidasSet.add(numCarta);
        }
      }

      // Atualiza o doc cartas_obtidas usando arrayUnion (ou cria se não existir)
      if (novosNumsParaAdicionar.isNotEmpty) {
        if (cartasObtidasDoc.exists) {
          await cartasObtidasRef.update({
            'cartas_obtidas': FieldValue.arrayUnion(novosNumsParaAdicionar),
          });
        } else {
          await cartasObtidasRef.set({'cartas_obtidas': novosNumsParaAdicionar});
        }
        print("Novas cartas adicionadas a cartas_obtidas (meu usuário): $novosNumsParaAdicionar");
      } else {
        print("Nenhuma carta nova para adicionar em cartas_obtidas (meu usuário).");
      }

      // Remover registro de contraproposta_recebida
      await firestore
          .collection("usuarios")
          .doc(uid)
          .collection("estatisticas")
          .doc("propostas")
          .collection("contraproposta_recebida")
          .doc(amigoUid)
          .delete();
    }

    // ------------------------
    // 2️⃣ Banco do amigo (quem enviou a contraproposta)
    // ------------------------
    // Remover cartas em contraproposta_enviada (amigo)
    final contrapropostaEnviadaDoc = await firestore
        .collection("usuarios")
        .doc(amigoUid)
        .collection("estatisticas")
        .doc("propostas")
        .collection("contraproposta_enviada")
        .doc(uid)
        .get();

    if (contrapropostaEnviadaDoc.exists) {
      final cartas =
          Map<String, dynamic>.from(contrapropostaEnviadaDoc.data()!['cartas'] ?? {});
      for (var cartaId in cartas.keys) {
        await firestore
            .collection("usuarios")
            .doc(amigoUid)
            .collection("inventario")
            .doc("itens")
            .collection("colecao")
            .doc(cartaId)
            .delete();
      }

      await firestore
          .collection("usuarios")
          .doc(amigoUid)
          .collection("estatisticas")
          .doc("propostas")
          .collection("contraproposta_enviada")
          .doc(uid)
          .delete();
    }

    // Cartas em recebidas (no amigo) -> adiciona ao inventário do amigo e atualiza cartas_obtidas do amigo
    final recebidasDoc = await firestore
        .collection("usuarios")
        .doc(amigoUid)
        .collection("estatisticas")
        .doc("propostas")
        .collection("recebidas")
        .doc(uid)
        .get();

    if (recebidasDoc.exists) {
      final cartas = Map<String, dynamic>.from(recebidasDoc.data()!['cartas'] ?? {});

      // Referência ao doc cartas_obtidas do amigo
      final cartasObtidasRefAmigo = firestore
          .collection("usuarios")
          .doc(amigoUid)
          .collection("inventario")
          .doc("itens")
          .collection("cartas_obtidas")
          .doc("lista");

      final cartasObtidasDocAmigo = await cartasObtidasRefAmigo.get();

      final Set<String> obtidasSetAmigo = {};
      if (cartasObtidasDocAmigo.exists) {
        final raw = cartasObtidasDocAmigo.data()?['cartas_obtidas'] ?? [];
        for (var e in List.from(raw)) {
          if (e != null) obtidasSetAmigo.add(e.toString());
        }
      }

      final List<String> novosNumsParaAmigo = [];

      for (var cartaEntry in cartas.entries) {
        final cartaId = cartaEntry.key;
        final cartaData = Map<String, dynamic>.from(cartaEntry.value);

        // Adicionar carta ao inventário do amigo
        await firestore
            .collection("usuarios")
            .doc(amigoUid)
            .collection("inventario")
            .doc("itens")
            .collection("colecao")
            .doc(cartaId)
            .set(cartaData);

        // Atualizar lista de nums do amigo
        final numCarta = cartaData['num']?.toString();
        if (numCarta != null && !obtidasSetAmigo.contains(numCarta)) {
          novosNumsParaAmigo.add(numCarta);
          obtidasSetAmigo.add(numCarta);
        }
      }

      // Atualiza o doc cartas_obtidas do amigo
      if (novosNumsParaAmigo.isNotEmpty) {
        if (cartasObtidasDocAmigo.exists) {
          await cartasObtidasRefAmigo.update({
            'cartas_obtidas': FieldValue.arrayUnion(novosNumsParaAmigo),
          });
        } else {
          await cartasObtidasRefAmigo.set({'cartas_obtidas': novosNumsParaAmigo});
        }
        print("Novas cartas adicionadas a cartas_obtidas (amigo): $novosNumsParaAmigo");
      } else {
        print("Nenhuma carta nova para adicionar em cartas_obtidas (amigo).");
      }

      // Remover registro de recebidas do amigo
      await firestore
          .collection("usuarios")
          .doc(amigoUid)
          .collection("estatisticas")
          .doc("propostas")
          .collection("recebidas")
          .doc(uid)
          .delete();
    }
    print("✅ Troca confirmada com sucesso e cartas_obtidas atualizadas!");
  } catch (e, st) {
    print("Erro ao confirmar troca: $e\n$st");
    rethrow;
  }
}



Future<void> recusarProposta(String remetenteUid) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final meuDocRecebidas = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(uid)
      .collection("estatisticas")
      .doc("propostas")
      .collection("recebidas")
      .doc(remetenteUid);

  final docEnviadasRemetente = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(remetenteUid)
      .collection("estatisticas")
      .doc("propostas")
      .collection("enviadas")
      .doc(uid);

  // Remove os documentos em paralelo
  await Future.wait([
    meuDocRecebidas.delete(),
    docEnviadasRemetente.delete(),
  ]);

  print("Proposta do usuário $remetenteUid recusada com sucesso!");
}

Future<void> recusarContraproposta(String amigoUid) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // --- Remove registros do usuário atual ---
  final userPropostas = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(uid)
      .collection("estatisticas")
      .doc("propostas");

  await Future.wait([
    userPropostas.collection("enviadas").doc(amigoUid).delete(),
    userPropostas.collection("contraproposta_recebida").doc(amigoUid).delete(),
  ]);

  // --- Remove registros do amigo ---
  final amigoPropostas = FirebaseFirestore.instance
      .collection("usuarios")
      .doc(amigoUid)
      .collection("estatisticas")
      .doc("propostas");

  await Future.wait([
    amigoPropostas.collection("recebidas").doc(uid).delete(),
    amigoPropostas.collection("contraproposta_enviada").doc(uid).delete(),
  ]);
}


