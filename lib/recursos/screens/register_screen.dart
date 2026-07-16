import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. CONTROLADORES PARA CAPTURAR LA INFORMACIÓN
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // <--- Necesaria para Auth

  // Variables de control de tipo de formulario y tipo de documento
  bool _esEmpresa = false;
  String _cedulaTipo = 'V';
  String _rifTipo = 'J';

  @override
  void dispose() {
    // Limpieza de controladores al cerrar la pantalla
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. FUNCIÓN PRINCIPAL DE ENLACE AUTH + FIRESTORE
  Future<void> _procesarRegistro() async {
    try {
      // Mostrar un indicador de carga circular
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2E16D1))),
      );

      // A. Crear el usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // B. Obtener el UID único que Auth le otorgó
      String uid = userCredential.user!.uid;

      // C. Preparar los datos según sea usuario o empresa
      final String rol = _esEmpresa ? "empresa" : "usuario";
      final String identificacion = _esEmpresa
          ? "$_rifTipo-${_cedulaController.text.trim()}"
          : "$_cedulaTipo-${_cedulaController.text.trim()}";

      final Map<String, dynamic> datosUsuario = {
        'uid': uid,
        'nombres': _nombreController.text.trim(),
        'apellidos': _esEmpresa ? "" : _apellidoController.text.trim(),
        'cedula': identificacion, // Mantenemos cedula para compatibilidad con pantallas existentes
        'telefono': _telefonoController.text.trim(),
        'correo': _emailController.text.trim(),
        'rol': rol,
        'fecha_registro': FieldValue.serverTimestamp(),
      };

      if (_esEmpresa) {
        datosUsuario['rif'] = identificacion;
      }

      // D. Guardar los datos del formulario en Firestore usando ese UID exacto
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(datosUsuario);

      // E. Si es empresa, también agregar a la colección 'empresas' para ser listada
      if (_esEmpresa) {
        await FirebaseFirestore.instance.collection('empresas').doc(uid).set({
          'nombre': _nombreController.text.trim(),
          'rif': identificacion,
          'contacto': _telefonoController.text.trim(),
          'fechaRegistro': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Quitar el círculo de carga

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Registro exitoso en ESK-PE!'), backgroundColor: Colors.green),
      );

      // Aquí puedes redirigir a tu HomeScreen o Login
       Navigator.pop(
        context,
        MaterialPageRoute(builder: (context)=> const HomeScreen())); 

    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Quitar carga
      String mensajeError = 'Ocurrió un error en el registro.';
      if (e.code == 'email-already-in-use') mensajeError = 'Este correo ya está registrado.';
      if (e.code == 'weak-password') mensajeError = 'La contraseña es muy débil.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error detallado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: size.width,
                height: size.height,
                child: Image.asset(
                  'assets/background_road.jpg',
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          
          // Gradiente superpuesto
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            ),
          ),

          Positioned(
            top: size.height * 0.15,
            left: 0,
            right: 0,
            bottom: -20, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    const Text(
                      "Crea tu cuenta",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E16D1),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 1. SELECTOR DE TIPO DE FORMULARIO
                    Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0ECFF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _esEmpresa = false;
                                  _cedulaController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_esEmpresa ? const Color(0xFF2E16D1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: !_esEmpresa ? [
                                    BoxShadow(
                                      color: const Color(0xFF2E16D1).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ] : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Viajero",
                                    style: TextStyle(
                                      color: !_esEmpresa ? Colors.white : const Color(0xFF2E16D1),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _esEmpresa = true;
                                  _cedulaController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _esEmpresa ? const Color(0xFF2E16D1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: _esEmpresa ? [
                                    BoxShadow(
                                      color: const Color(0xFF2E16D1).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ] : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Empresa",
                                    style: TextStyle(
                                      color: _esEmpresa ? Colors.white : const Color(0xFF2E16D1),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    _buildTextField(
                      _esEmpresa ? "Razón Social / Nombre" : "Nombres", 
                      TextInputType.name,
                      _nombreController,
                      (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _esEmpresa ? 'Ingresa el nombre de la empresa' : 'Ingresa tus nombres';
                        }
                        if (!_esEmpresa && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(value)) {
                          return 'Los nombres no deben contener números';
                        }
                        return null;
                      },
                      inputFormatters: _esEmpresa ? null : [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))],
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: _esEmpresa ? Icons.business : Icons.person_outline,
                    ),
                    
                    const SizedBox(height: 20),

                    if (!_esEmpresa) ...[
                      _buildTextField(
                        "Apellidos", 
                        TextInputType.name,
                        _apellidoController,
                        (value) {
                          if (value == null || value.trim().isEmpty) return 'Ingresa tus apellidos';
                          if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(value)) return 'Los apellidos no deben contener números';
                          return null;
                        },
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))],
                        textCapitalization: TextCapitalization.words,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_esEmpresa),
                            initialValue: _esEmpresa ? _rifTipo : _cedulaTipo,
                            dropdownColor: Colors.white,
                            items: (_esEmpresa ? ['J', 'G', 'V', 'E'] : ['V', 'E'])
                                .map((tipo) => DropdownMenuItem(
                                      value: tipo,
                                      child: Text(
                                        tipo, 
                                        style: const TextStyle(
                                          color: Color(0xFF2E16D1),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  if (_esEmpresa) {
                                    _rifTipo = val;
                                  } else {
                                    _cedulaTipo = val;
                                  }
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Tipo',
                              labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontWeight: FontWeight.w500),
                              filled: true,
                              fillColor: const Color(0xFFF7F7F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: const BorderSide(color: Color(0xFF4A3AFF), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            _esEmpresa ? "Número RIF" : "Cédula de Identidad", 
                            TextInputType.number,
                            _cedulaController,
                            (value) {
                              if (value == null || value.isEmpty) {
                                return _esEmpresa ? 'El RIF es obligatorio' : 'La cédula es obligatoria';
                              }
                              if (_esEmpresa && value.length < 9) {
                                return 'Debe tener 9 dígitos';
                              }
                              if (!_esEmpresa && value.length < 6) {
                                return 'Debe tener al menos 6 dígitos';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(_esEmpresa ? 9 : 8), 
                            ], 
                            prefixIcon: Icons.badge_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      "Número telefónico", 
                      TextInputType.phone,
                      _telefonoController,
                      (value) {
                        if (value == null || value.isEmpty) return 'El número es obligatorio';
                        if (value.length < 11) return 'Debe tener 11 dígitos (Ej: 04141234567)';
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, 
                        LengthLimitingTextInputFormatter(11),   
                      ],
                      prefixIcon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      "Correo electrónico", 
                      TextInputType.emailAddress,
                      _emailController,
                      (value) {
                        if (value == null || value.isEmpty) return 'El correo es obligatorio';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) return 'Ingresa un correo válido';
                        return null;
                      },
                      prefixIcon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      "Contraseña", 
                      TextInputType.text,
                      _passwordController,
                      (value) {
                        if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
                        if (value.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                    ),

                    const SizedBox(height: 40),

                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E16D1), Color(0xFF4A3AFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A3AFF).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _procesarRegistro();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                        ),
                        child: const Text(
                          'REGISTRARSE',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 25),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: "¿Ya tienes cuenta? ",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                          children: [
                            TextSpan(
                              text: "Inicia sesión",
                              style: TextStyle(
                                color: Color(0xFF4A3AFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

          Positioned(
            top: size.height * 0.06,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ESK-PE',
                style: TextStyle(
                  fontFamily: 'Impact',
                  fontSize: 55,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
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

  Widget _buildTextField(
    String label, 
    TextInputType type, 
    TextEditingController controller,
    String? Function(String?)? validator,
    {List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    IconData? prefixIcon}
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      inputFormatters: inputFormatters, 
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF333333)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontWeight: FontWeight.w500),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF4A3AFF)) : null,
        filled: true,
        fillColor: const Color(0xFFF7F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: Color(0xFF4A3AFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}