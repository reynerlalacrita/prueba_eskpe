import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🛠️ Agregado para leer los datos de Firestore
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  // Variables para controlar el estado de los interruptores
  bool _modoOscuro = false;
  bool _notificaciones = false;

  // 🛠️ Variable para almacenar el nombre del usuario
  String _nombreUsuario = 'Cargando...';
  String _apellidoUsuario = '';

  @override
  void initState() {
    super.initState();
    _obtenerNombreDesdeFirebase();
  }

  // 🛠️ Función para jalar el nombre desde Firestore
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
          setState(() {
            // Si no tiene campo 'nombre', usa el de Auth, o por defecto 'Viajero'
            _nombreUsuario = datos['nombres'] ?? usuarioActual.displayName ?? 'Viajero';
            _apellidoUsuario = datos ['apellidos'];
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error al obtener el nombre: $e");
    }
    setState(() => _nombreUsuario = 'Viajero');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Fondo gris muy claro para resaltar las tarjetas blancas
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
                  color: const Color(0xFF1E2A4F),
                ),
                // Foto de perfil posicionada en el borde inferior
                Positioned(
                  bottom: -50,
                  child: Container(
                    padding: const EdgeInsets.all(4), // Efecto de borde blanco
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      // Aquí puedes usar un NetworkImage si descargas la foto del usuario desde Firebase
                      backgroundImage: AssetImage('assets/placeholder_user.jpg'), 
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60), // Espacio ajustado para que la foto no pise el texto

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
            const SizedBox(height: 25), // Espacio entre el nombre y la primera tarjeta

            // 2. PRIMERA TARJETA (Opciones de cuenta)
            _buildMenuCard(
              children: [
                _buildMenuItem(Icons.person_outline, "Mis Datos"),
                _buildMenuItem(Icons.lock_outline, "Seguridad y Contraseña"),
                _buildMenuItem(Icons.credit_card, "Métodos de Pago"),
                _buildMenuItem(Icons.tune, "Historial de Viajes"),
                _buildMenuItem(Icons.help_outline, "Ayuda y Soporte"),
              ],
            ),
            const SizedBox(height: 15),

            // 3. SEGUNDA TARJETA (Ajustes con interruptores)
            _buildMenuCard(
              children: [
                _buildSwitchItem(
                  _modoOscuro ? Icons.dark_mode : Icons.dark_mode_outlined, 
                  "Modo Oscuro", 
                  _modoOscuro, 
                  (valor) => setState(() => _modoOscuro = valor)
                ),
                _buildSwitchItem(
                  _notificaciones ? Icons.notifications_active : Icons.notifications_none_outlined, 
                  "Notificaciones", 
                  _notificaciones, 
                  (valor) => setState(() => _notificaciones = valor)
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
                      MaterialPageRoute(builder: (context) => const LoginScreen()), 
                      (route) => false
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Color(0xFFA53030)),
                label: const Text(
                  "Cerrar Sesión", 
                  style: TextStyle(color: Color(0xFFA53030), fontSize: 16, fontWeight: FontWeight.w600)
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  side: const BorderSide(color: Color(0xFFA53030), width: 1.2), // Borde rojo
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      child: Column(
        children: children,
      ),
    );
  }

  // Crea cada fila de opción estándar
  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E2A4F)),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
      onTap: () {
        // Lógica futura de navegación
      },
    );
  }

  // Crea cada fila con interruptor (Switch)
  Widget _buildSwitchItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E2A4F)),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF1E2A4F),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }
}