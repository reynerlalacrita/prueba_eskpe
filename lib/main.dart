import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/screens/home_screen.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';
import 'package:prueba_eskpe/recursos/screens/verificacion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización manual para Android
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyApadeihrG50p_pATvrd8Unfy36nIJ7vjo",
      appId: "1:143524415006:android:f6658891b2525dd5a5d00f",
      messagingSenderId: "143524415006",
      projectId: "trabajo-5aecf",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESK-PE App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2E16D1),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E16D1),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            User user = snapshot.data!;
            if (user.emailVerified) {
              return const HomeScreen();
            } else {
              return const VerificacionScreen();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}