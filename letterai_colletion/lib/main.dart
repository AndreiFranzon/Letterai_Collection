import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'packa4ge:flutter/services.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'Login/login_page.dart';
import 'Menu/home_page.dart';
import 'Database_Support/pontos_provider.dart';
import 'Database_Support/exercise_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = PontosProvider();
            provider.iniciarListener();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => dadosDiariosProvider()),
      ],
      child: MaterialApp(
        title: 'Login com Google',
        debugShowCheckedModeBanner: false,
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final user = snapshot.data;
              if (user == null) {
                return const LoginPage();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final dadosProvider = Provider.of<dadosDiariosProvider>(
                    context,
                    listen: false,
                  );
                  await dadosProvider.carregarDados();
                });
                return const HomePage();
              }
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
