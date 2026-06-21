import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_core/firebase_core.dart';
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
  final TextEditingController _dateController = TextEditingController();

  // Variable interna para asignar el rol por defecto en el registro público
  final String _rolPorDefecto = "usuario"; 

  @override
  void dispose() {
    // Limpieza de controladores al cerrar la pantalla
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), 
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
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

      // C. Guardar los datos del formulario en Firestore usando ese UID exacto
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombres': _nombreController.text.trim(),
        'apellidos': _apellidoController.text.trim(),
        'cedula': _cedulaController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'correo': _emailController.text.trim(),
        'fecha_nacimiento': _dateController.text,
        'rol': _rolPorDefecto, // Aquí se amarra el rol de "usuario"
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Quitar el círculo de carga

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Registro exitoso en ESK-PE!'), backgroundColor: Colors.green),
      );

      // Aquí puedes redirigir a tu HomeScreen o Login
       Navigator.pop(
        context,
        MaterialPageRoute(builder: (context)=> const HomeScreen())); 

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Quitar carga
      String mensajeError = 'Ocurrió un error en el registro.';
      if (e.code == 'email-already-in-use') mensajeError = 'Este correo ya está registrado.';
      if (e.code == 'weak-password') mensajeError = 'La contraseña es muy débil.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.pop(context);
      print("Error detallado: $e");
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

          Positioned(
            top: size.height * 0.15, // Bajamos un pelo para dar más aire
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
                    const SizedBox(height: 50), 
                    
                    _buildTextField(
                      "Nombres", 
                      TextInputType.name,
                      _nombreController, // <--- ASIGNADO
                      (value) {
                        if (value == null || value.trim().isEmpty) return 'Por favor, ingresa tus nombres';
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(value)) return 'Los nombres no deben contener números';
                        return null;
                      },
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))],
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 20),

                    _buildTextField(
                      "Apellidos", 
                      TextInputType.name,
                      _apellidoController, // <--- ASIGNADO
                      (value) {
                        if (value == null || value.trim().isEmpty) return 'Por favor, ingresa tus apellidos';
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(value)) return 'Los apellidos no deben contener números';
                        return null;
                      },
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))],
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      "Cédula de Identidad", 
                      TextInputType.number,
                      _cedulaController, // <--- ASIGNADO
                      (value) {
                        if (value == null || value.isEmpty) return 'La cédula es obligatoria';
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8), 
                      ], 
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      "Número telefónico", 
                      TextInputType.phone,
                      _telefonoController, // <--- ASIGNADO
                      (value) {
                        if (value == null || value.isEmpty) return 'El número telefónico es obligatorio';
                        if (value.length < 11) return 'Debe tener 11 dígitos (Ej: 04141234567)';
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, 
                        LengthLimitingTextInputFormatter(11),   
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      "Correo electrónico", 
                      TextInputType.emailAddress,
                      _emailController, // <--- ASIGNADO
                      (value) {
                        if (value == null || value.isEmpty) return 'El correo electrónico es obligatorio';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) return 'Ingresa un correo electrónico válido';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // CAMPO NUEVO IMPRESCINDIBLE PARA FIREBASE AUTH
                    _buildTextField(
                      "Contraseña", 
                      TextInputType.text,
                      _passwordController, // <--- ASIGNADO
                      (value) {
                        if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
                        if (value.length < 6) return 'La contraseña debe tener mínimo 6 caracteres';
                        return null;
                      },
                      obscureText: true, // Oculta los caracteres de la clave
                    ),

                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Selecciona tu fecha de nacimiento';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        labelStyle: TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.w500),
                        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF4A3AFF)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD6C7FF), width: 2)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A3AFF), width: 2)),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Ejecutamos el registro amarrado
                            _procesarRegistro();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E16D1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'REGISTRARSE',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "¿Ya tienes cuenta? Inicia sesión",
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

          Positioned(
            top: size.height * 0.06,
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

  Widget _buildTextField(
    String label, 
    TextInputType type, 
    TextEditingController controller, // <--- AHORA EL WIDGET PIDE EL CONTROLLER
    String? Function(String?)? validator,
    {List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false} // <--- PARÁMETRO PARA OCULTAR CLAVE
  ) {
    return TextFormField(
      controller: controller, // <--- SE LO CORRESPONDEMOS AQUÍ
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