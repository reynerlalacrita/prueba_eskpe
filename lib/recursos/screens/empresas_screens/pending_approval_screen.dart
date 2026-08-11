import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/home_empresa_screen.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isChecking = false;

  // Consultar a Firestore si la cuenta fue aprobada
  Future<void> _verificarEstado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _cerrarSesion();
      return;
    }

    setState(() => _isChecking = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final String estado = doc.data()?['estado'] ?? 'pending';

        if (estado == 'active') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Tu cuenta ha sido aprobada! Bienvenido a ESK-PE.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeEmpresaScreen()),
            (route) => false,
          );
        } else if (estado == 'rejected') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu solicitud de registro de empresa ha sido rechazada.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu solicitud aún está en revisión por el equipo de ESK-PE.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron datos de la cuenta.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  // Cerrar sesión y regresar al login
  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E16D1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ── Ícono ilustrativo de reloj/espera ───────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.white,
                size: 54,
              ),
            ),

            const SizedBox(height: 24),

            // ── Título ────────────────────────────────────────────────
            const Text(
              'Solicitud en Revisión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 36),

            // ── Tarjeta blanca principal ──────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50.0),
                    topRight: Radius.circular(50.0),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Badge de estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pending_actions_rounded, size: 18, color: Colors.orange.shade800),
                            const SizedBox(width: 8),
                            Text(
                              'Estado: Pendiente',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Mensaje informativo
                      Text(
                        'Hemos recibido los datos de tu empresa. Nuestro equipo está verificando la información. Te notificaremos una vez que tu cuenta sea aprobada para comenzar a operar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Botón Principal: Verificar Estado ───────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isChecking ? null : _verificarEstado,
                          icon: _isChecking
                              ? const SizedBox.shrink()
                              : const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: _isChecking
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'VERIFICAR ESTADO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E16D1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Divider(color: Colors.grey[200]),

                      const SizedBox(height: 16),

                      // ── Botón secundario: Cerrar Sesión ─────────────
                      TextButton.icon(
                        onPressed: _cerrarSesion,
                        icon: const Icon(Icons.logout_rounded, color: Colors.grey, size: 20),
                        label: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
