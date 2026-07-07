import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            const SizedBox(height: 70), // Espacio necesario por la imagen sobresaliente

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