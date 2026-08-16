import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prueba_eskpe/recursos/screens/splash_screen.dart';
import 'package:prueba_eskpe/recursos/colores.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización manual para Android
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey:
          "AIzaSyApadeihrG50p_pATvrd8Unfy36nIJ7vjo", // La encuentras dentro del google-services.json
      appId:
          "1:143524415006:android:f6658891b2525dd5a5d00f", // La encuentras dentro del google-services.json
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
      debugShowCheckedModeBanner:
          false, // Quita la etiqueta roja de "Debug" en la esquina
      theme: ThemeData(
        primaryColor: AppColors.azulEskpe,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azulEskpe,
          primary: AppColors.azulEskpe,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.azulEskpe,
          foregroundColor: AppColors.blancofondo,
        ),
        useMaterial3: true,
      ),
      // CONFIGURA LA PANTALLA INICIAL: SplashScreen verifica la sesión y el rol
      home: const SplashScreen(),
    );
  }
}
