import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/home_empresa_screen.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesionYRol();
  }

  Future<void> _verificarSesionYRol() async {
    // Pequeño delay estético para mostrar la pantalla de carga/logo
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No hay sesión activa -> Ir al Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    try {
      // Consultar el documento del usuario en Firestore para obtener su rol
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final String rol = doc.get('rol') ?? 'usuario';
        debugPrint("Sesión detectada. Rol de usuario: $rol");

        if (rol == 'empresa') {
          // Redirigir al panel exclusivo de empresa
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeEmpresaScreen()),
          );
        } else {
          // Redirigir al HomeScreen exclusivo para usuarios/clientes
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // Si el usuario existe en Auth pero no en Firestore, redirigir a HomeScreen por defecto
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error al verificar rol en SplashScreen: $e");
      if (!mounted) return;
      // En caso de error de red u otro, redirigir a Login o HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ya no usamos el backgroundColor aquí
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            // Reemplaza 'assets/fondo_splash.jpg' con la ruta real de tu imagen
            image: AssetImage('assets/background_road.jpg'), 
            fit: BoxFit.cover, // Esto asegura que la imagen cubra toda la pantalla sin deformarse
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ESK-PE
              Text(
                'ESK-PE',
                style: TextStyle(
                  fontFamily: 'Impact',
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu aventura empieza aquí',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
