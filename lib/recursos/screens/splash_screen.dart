import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/home_empresa_screen.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/pending_approval_screen.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/home_screen.dart';
import 'package:prueba_eskpe/recursos/screens/verification_screen.dart';

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
          // Para empresas: verificar estado de aprobación
          final String estado = doc.data()?['estado'] ?? 'pending';
          if (estado == 'pending') {
            // Empresa pendiente: mostrar pantalla de espera
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PendingApprovalScreen()),
            );
            return;
          } else if (estado == 'rejected') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeEmpresaScreen()),
          );
        } else {
          // Para viajeros: usar verificación nativa de Firebase Auth
          await user.reload();
          final refreshedUser = FirebaseAuth.instance.currentUser;

          if (refreshedUser != null && !refreshedUser.emailVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationScreen(
                  email: refreshedUser.email ?? doc.data()?['correo'] ?? '',
                ),
              ),
            );
            return;
          }

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset(
            'assets/background_road.jpg',
            fit: BoxFit.cover,
          ),
          // Capa oscura semitransparente
          Container(
            color: Colors.black.withOpacity(0.52),
          ),
          // Contenido centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
        ],
      ),
    );
  }
}
