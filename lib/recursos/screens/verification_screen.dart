import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/screens/register_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isChecking = false;
  bool _canResend = false;
  int _secondsLeft = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // Inicia el temporizador de 60 segundos para reenviar
  void _startCooldownTimer() {
    setState(() {
      _canResend = false;
      _secondsLeft = 60;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // Botón principal: verificar si el enlace fue tocado
  Future<void> _verificarCorreo() async {
    setState(() => _isChecking = true);

    try {
      // Recargar el estado del usuario desde Firebase Auth
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user != null && user.emailVerified) {
        // ✅ Correo verificado: ir a la pantalla principal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Correo verificado! Bienvenido a ESK-PE.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // ⚠️ Aún no ha verificado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu correo aún no ha sido verificado. Revisa tu bandeja de entrada o spam.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  // Reenviar correo de verificación
  Future<void> _reenviarCorreo() async {
    if (!_canResend) return;

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo de verificación reenviado. Revisa tu bandeja de entrada.'),
          backgroundColor: Colors.green,
        ),
      );

      _startCooldownTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reenviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Volver al registro: cerrar sesión para evitar conflictos
  Future<void> _volverAlRegistro() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
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
            // ── Header con flecha de regreso ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _volverAlRegistro,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    tooltip: 'Volver al registro',
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ── Ícono de correo animado ───────────────────────────────
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.white,
                size: 54,
              ),
            ),

            const SizedBox(height: 24),

            // ── Título ────────────────────────────────────────────────
            const Text(
              'Verifica tu correo',
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

                      // Mensaje informativo
                      Text(
                        'Hemos enviado un enlace de verificación a:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Correo del usuario
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0ECFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E16D1),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'Revisa tu bandeja de entrada o la carpeta de spam y toca el enlace para activar tu cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Botón principal ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _verificarCorreo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E16D1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isChecking
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'YA VERIFIQUÉ MI CORREO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Botón reenviar con cooldown ─────────────────
                      _canResend
                          ? TextButton.icon(
                              onPressed: _reenviarCorreo,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF2E16D1),
                                size: 20,
                              ),
                              label: const Text(
                                'Reenviar correo',
                                style: TextStyle(
                                  color: Color(0xFF2E16D1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : Text(
                              'Reenviar correo en $_secondsLeft s',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),

                      const SizedBox(height: 32),

                      // ── Divisor ─────────────────────────────────────
                      Divider(color: Colors.grey[200]),

                      const SizedBox(height: 16),

                      // ── Enlace de regreso ───────────────────────────
                      TextButton(
                        onPressed: _volverAlRegistro,
                        child: const Text(
                          '¿Correo incorrecto? Volver al registro',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
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
