import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/historial_reservas_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/mis_datos_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/soporte_screen.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  // 🛠️ Variable para almacenar el nombre del usuario
  String _nombreUsuario = 'Cargando...';
  String _apellidoUsuario = '';
  String rol = 'usuario';
  bool cargandoRol = true;

  @override
  void initState() {
    super.initState();
    _obtenerNombreDesdeFirebase();
  }

  void _obtenerNombreDesdeFirebase() async {
    try {
      User? usuarioActual = FirebaseAuth.instance.currentUser;
      if (usuarioActual != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioActual.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> datos = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              // Si no tiene campo 'nombre', usa el de Auth, o por defecto 'Viajero'
              _nombreUsuario =
                  datos['nombres'] ?? usuarioActual.displayName ?? 'Viajero';
              _apellidoUsuario = datos['apellidos'] ?? '';
              rol = datos['rol'] ?? 'usuario';
              cargandoRol = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error al obtener el nombre: $e");
    }
    if (mounted) {
      setState(() => _nombreUsuario = 'Viajero');
    }
  }

  @override
  Widget build(BuildContext context) {
    User? usuarioActual = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors
          .blancofondo, // Fondo gris muy claro para resaltar las tarjetas blancas
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. ENCABEZADO AZUL Y FOTO DE PERFIL SUPERPUESTA
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Fondo azul oscuro superior
                Container(
                  height: 160,
                  width: double.infinity,
                  color: AppColors.azuleskpe,
                ),
                // Foto de perfil posicionada en el borde inferior (Dinámica con StreamBuilder)
                Positioned(
                  bottom: -50,
                  child: Container(
                    padding: const EdgeInsets.all(4), // Efecto de borde blanco
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: usuarioActual != null
                          ? FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(usuarioActual.uid)
                                .snapshots()
                          : null,
                      builder: (context, snapshot) {
                        String? fotoUrl;
                        if (snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          fotoUrl = data?['fotoUrl'] ?? usuarioActual?.photoURL;
                        } else {
                          fotoUrl = usuarioActual?.photoURL;
                        }

                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              (fotoUrl != null && fotoUrl.isNotEmpty)
                              ? NetworkImage(fotoUrl) as ImageProvider
                              : const AssetImage('assets/sinfoto.jpg'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 60,
            ), // Espacio ajustado para que la foto no pise el texto
            // 🛠️ EL NOMBRE DEL USUARIO (SÓLO EL NOMBRE)
            Text(
              '$_nombreUsuario $_apellidoUsuario',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A4F), // Azul oscuro para combinar
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 25,
            ), // Espacio entre el nombre y la primera tarjeta
            // 2. PRIMERA TARJETA (Opciones de cuenta)
            _buildMenuCard(
              children: [
                _buildMenuItem(
                  Icons.person_outline,
                  "Mis Datos",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MisDatosScreen(),
                      ),
                    );
                    _obtenerNombreDesdeFirebase();
                  },
                ),
                _buildMenuItem(
                  Icons.tune,
                  "Historial de Viajes",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistorialReservasScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.help_outline,
                  "Ayuda y Soporte",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoporteScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 4. BOTÓN DE CERRAR SESIÓN CON LOGICA DE FIREBASE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Color(0xFFA53030)),
                label: const Text(
                  "Cerrar Sesión",
                  style: TextStyle(
                    color: Color(0xFFA53030),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  side: const BorderSide(
                    color: Color(0xFFA53030),
                    width: 1.2,
                  ), // Borde rojo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS REUTILIZABLES PARA MANTENER EL CÓDIGO LIMPIO ---

  // Crea el contenedor blanco con sombra suave
  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Crea cada fila de opción estándar
  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E2A4F)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap:
          onTap ??
          () {
            // Lógica futura de navegación
          },
    );
  }
}
