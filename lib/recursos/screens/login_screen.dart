import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Variable para controlar si la tarjeta de login ya subió o no
  bool _mostrarLogin = false;

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla para que sea responsivo
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC), // Fondo gris de los laterales/abajo
      body: Stack(
        children: [
          // 1. Imagen de fondo (Ocupa toda la pantalla al inicio, y se mantiene fija atrás)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background_road.jpg'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. Filtro oscuro opcional cuando la tarjeta no ha subido (para mejorar contraste del botón)
          if (!_mostrarLogin)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),

          // 3. Botón inicial "INICIAR" (Solo se ve si la tarjeta está oculta)
          if (!_mostrarLogin)
            Positioned(
              bottom: 60,
              left: 30,
              right: 30,
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Al presionar, cambiamos el estado para activar la animación de subida
                    setState(() {
                      _mostrarLogin = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E16D1), // Morado eléctrico
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'ESCAPATE AHORA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

          // 5. Tarjeta blanca animada con los elementos del Login
          AnimatedPositioned(
            duration: const Duration(milliseconds: 550),
            curve: Curves.fastOutSlowIn, // Curva de animación suave y natural
            // Si _mostrarLogin es falso, se esconde abajo del todo (size.height)
            top: _mostrarLogin ? size.height * 0.28 : size.height, 
            left: 0,
            right: 0,
            bottom: 0, // Se expande hasta el fondo de la pantalla
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 100.0),
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
                    // Espacio para darle holgura al diseño por debajo del logo animado
                    SizedBox(height: size.height * 0.10),

                    // Campo de Gmail
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Gmail',
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
                    
                    SizedBox(height: size.height * 0.05),

                    // Botón INICIAR SESIÓN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // Acción del botón de iniciar sesión
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E16D1),
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
                    
                    const SizedBox(height: 15),
                    
                    // Texto Recuperar contraseña
                    TextButton(
                      onPressed: () {
                        // Acción de recuperar contraseña
                      },
                      child: const Text(
                        'Recuperar contraseña',
                        style: TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Fila de Registro: Texto pequeño + enlace
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No tienes una cuenta todavía? ',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Acción para redirigir al registro
                          },
                          child: const Text(
                            'Regístrate!',
                            style: TextStyle(
                              color: Color(0xFF2E16D1),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

                    // 4. Logo / Título "ESK-PE" con animación de posición y color
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic, // Movimiento fluido
            top: _mostrarLogin ? size.height * 0.34 : size.height * 0.35,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ESK-PE',
                style: TextStyle(
                  fontFamily: 'Impact',
                  fontSize: _mostrarLogin ? 68 : 75,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  // Si la tarjeta subió, se vuelve gris oscuro; si está sobre la foto, blanco
                  color: _mostrarLogin ? const Color(0xFF222222) : Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}