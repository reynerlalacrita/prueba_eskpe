import 'package:flutter/material.dart';
import 'package:prueba_eskpe/recursos/screens/home_screen.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';
// 1. IMPORTA TU PANTALLA: Cambia 'tu_proyecto' por el nombre real de tu proyecto de Flutter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESK-PE App',
      debugShowCheckedModeBanner: false, // Quita la etiqueta roja de "Debug" en la esquina
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Activa Material 3 para un diseño más moderno
      ),
      // 2. CONFIGURA LA PANTALLA INICIAL HERE
      home: const HomeScreen(), 
    );
  }
}