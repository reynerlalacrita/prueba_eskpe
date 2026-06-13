import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla para que sea responsivo
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC), // Fondo gris de los laterales/abajo
      body: Stack(
        children: [
          // 1. Imagen de fondo en la parte superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45, // Ocupa el 45% superior de la pantalla
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  // REEMPLAZA ESTO: Asegúrate de añadir tu imagen en pubspec.yaml
                  image: AssetImage('assets/background_road.jpg'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. Tarjeta blanca con los elementos del Login
          Positioned(
            top: size.height * 0.28, // Empieza un poco más arriba del final de la imagen
            left: 0,
            right: 0,
            bottom: 0, // Llega hasta el fondo de la pantalla
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    
                    // Logo / Título "ESK-PE"
                    const Text(
                      'ESK-PE',
                      style: TextStyle(
                        fontFamily: 'Impact', // O usa una fuente similar en negrita e itálica
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF222222),
                        letterSpacing: 2,
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.05),

                    // Campo de Gmail
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Gmail',
                        labelStyle: TextStyle(
                          color: Color(0xFF4A3AFF), // Azul/Morado del texto
                          fontWeight: FontWeight.w500,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD6C7FF), width: 2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A3AFF), width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // Campo de Contraseña
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: TextStyle(
                          color: Color(0xFF4A3AFF),
                          fontWeight: FontWeight.w500,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD6C7FF), width: 2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A3AFF), width: 2),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.06),

                    // Botón INICIAR SESIÓN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // Acción del botón
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E16D1), // Morado eléctrico
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF444444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "REGISTRATE!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                         ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Texto Forgot Password?
                    
                    TextButton(
                      onPressed: () { a a a a a
                        // Acción de recuperar contraseña
                      },
                      child: const Text(
                        'Recuperar contraseña',
                        style: TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }
}