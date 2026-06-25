import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/screens/home_screen.dart';
import 'package:prueba_eskpe/recursos/screens/destinos_screen.dart';
import 'register_screen.dart'; // <--- Asegúrate de que el nombre del archivo coincida

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para capturar las credenciales
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // FUNCIÓN PARA INICIAR SESIÓN Y LEER EL ROL
  Future<void> _procesarLogin() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2E16D1))),
      );

      // 1. Autenticar con Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 2. Buscar el documento del usuario en Firestore para saber su Rol
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      Navigator.pop(context); // Quitar el círculo de carga

      if (userDoc.exists) {
        String rol = userDoc.get('rol');
        print("Usuario autenticado con éxito. Rol: $rol");

        // --- SUSTITUYE DESDE AQUÍ ---
        if (rol == 'admin') {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const HomeScreen())
          );
        } else {
          // Redirige a DestinosScreen para usuarios normales
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const DestinosScreen())
          );
        }
        // --- HASTA AQUÍ ---
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Bienvenido de vuelta! Perfil: $rol'), backgroundColor: Colors.green),
        );

      } else {
        // Si por algún motivo el usuario está en Auth pero no en Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron datos de perfil.'), backgroundColor: Colors.orange),
        );
      }

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Quitar carga
      String mensajeError = 'Error al iniciar sesión.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensajeError = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        mensajeError = 'El formato del correo no es válido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.pop(context);
      print("Error en login: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fondo inmutable idéntico al registro
          SizedBox(
            width: size.width,
            height: size.height,
            child: Image.asset(
              'assets/background_road.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Tarjeta Blanca de Login
          Positioned(
            top: size.height * 0.30, // Más abajo que el registro porque son menos campos
            left: 0,
            right: 0,
            bottom: -20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      _buildTextField(
                        "Correo electrónico",
                        TextInputType.emailAddress,
                        _emailController,
                        (value) {
                          if (value == null || value.isEmpty) return 'Ingresa tu correo';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildTextField(
                        "Contraseña",
                        TextInputType.text,
                        _passwordController,
                        (value) {
                          if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                          return null;
                        },
                        obscureText: true,
                      ),

                      const SizedBox(height: 40),

                      // Botón Ingresar
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _procesarLogin();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E16D1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'INGRESAR',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Saltar al Registro
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "¿No tienes cuenta? Regístrate aquí",
                          style: TextStyle(
                            color: Color(0xFF444444),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Logo ESK-PE
          Positioned(
            top: size.height * 0.12,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'ESK-PE',
                style: TextStyle(
                  fontFamily: 'Impact',
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF222222),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Auxiliar de campos idéntico al de Register para mantener la consistencia visual
  Widget _buildTextField(
    String label,
    TextInputType type,
    TextEditingController controller,
    String? Function(String?)? validator, {
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.w500),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD6C7FF), width: 2)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A3AFF), width: 2)),
        errorStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
      ),
    );
  }
}