import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';

class UsuarioScreen extends StatelessWidget {
  const UsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Mi Perfil"), backgroundColor: const Color(0xFF2E16D1)),
      body: Column(
        children: [
          const SizedBox(height: 50),
          const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 80)),
          const SizedBox(height: 20),
          Text(FirebaseAuth.instance.currentUser?.email ?? "Usuario", style: const TextStyle(fontSize: 20)),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Cerrar Sesión"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}