import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package:letterai_colletion/Login/login_page.dart';
import 'package:letterai_colletion/Login/login_support.dart';

class AuthService {

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // 🔹 Inicializa estatísticas após login
    if (userCredential.user != null) {
      await inicializarEstatisticas(userCredential.user!);
      await FriendCode.friendCode(userCredential.user!);
    }

    return userCredential;
  } catch (e) {
    print('Erro ao fazer login com Google: $e');
    return null;
  }
}


Future<void> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    print('Logout realizado com sucesso.');
  } catch (e) {
    print('Erro no logout: $e');
  }
}

Future<void> logout(BuildContext context) async {
  await signOut();
 
}

}

