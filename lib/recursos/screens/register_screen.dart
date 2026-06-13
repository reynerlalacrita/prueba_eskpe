import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- NECESARIA PARA LOS FORMATTERS


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para capturar la información
  final TextEditingController _dateController = TextEditingController();
   final _formKey = GlobalKey<FormState>();

  // Función para abrir el selector de fecha (DatePicker)
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // Sugiere 18 años atrás
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC),
      resizeToAvoidBottomInset: true, // Permite que la tarjeta se desplace hacia arriba cuando se abre el teclado
      body: Stack(
        children: [
          // 1. Fondo fijo inmutable (Mismo que el login)
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

          // 2. Tarjeta Blanca de Registro (Fija, sin animación)
          Positioned(
            top: size.height * 0.18, // Se posiciona fija arriba de una vez
            left: 0,
            right: 0,
            bottom: -20, // Sella el borde inferior
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
                    const SizedBox(height: 50), // Espacio para que el logo no tape el contenido inicial
                    
                    _buildTextField(
                    "Nombres", 
                    TextInputType.name,
                    (value) {
                      if (value == null || value.trim().isEmpty) return 'Por favor, ingresa tus nombres';
                      // Validación extra por si copian y pegan texto inválido
                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(value)) return 'Los nombres no deben contener números ni símbolos';
                      return null;
                    },
                    // Expresión regular que permite solo letras (mayúsculas, minúsculas, acentos, eñes y espacios)
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))],
                    textCapitalization: TextCapitalization.words,
                  ),
                  
                  const SizedBox(height: 20),

                  _buildTextField(
                    "Apellidos", 
                    TextInputType.name,
                    (value) {
                      if (value == null || value.trim().isEmpty) return 'Por favor, ingresa tus apellidos';
                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(value)) return 'Los apellidos no deben contener números ni símbolos';
                      return null;
                    },
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))],
                    textCapitalization: TextCapitalization.words,
                  ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      "Cédula de Identidad", 
                      TextInputType.number,
                      (value) {
                        if (value == null || value.isEmpty) return 'La cédula es obligatoria';
                        return null;
                      },
                      // Este formatter solo deja pasar dígitos del 0 al 9
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8), 
                      ], 
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      "Número telefónico", 
                      TextInputType.phone,
                      (value) {
                        if (value == null || value.isEmpty) return 'El número telefónico es obligatorio';
                        // Validación por si acaso pegan un texto que no es
                        if (value.length < 11) return 'El número debe tener 11 dígitos (Ej: 04141234567)';
                        return null;
                      },
                      // Aquí le pasamos dos filtros en la lista:
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // 1. Solo permite números del 0 al 9
                        LengthLimitingTextInputFormatter(11),   // 2. Bloquea el teclado si intentan escribir un 12vo número
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                    "Correo electrónico", 
                    TextInputType.emailAddress,
                    (value) {
                      if (value == null || value.isEmpty) return 'El correo electrónico es obligatorio';
                      // Validación simple de estructura de correo usando expresiones regulares
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) return 'Ingresa un correo electrónico válido';
                      return null;
                    },
                  ),

                    const SizedBox(height: 20),
                    
                    // Campo para Fecha de Nacimiento
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

                    // Botón de Registro
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // Si todos los campos cumplen los requisitos, currentState!.validate() devuelve true
                          if (_formKey.currentState!.validate()) {
                            // ¡Perfecto! Todos los datos son válidos, aquí procesas el registro
                            print("Formulario válido. Registrando usuario...");
                          } else {
                            // Si algo falta, Flutter mostrará los textos de alerta automáticamente
                            print("Formulario inválido. Revisa los errores.");
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

                    // Volver al Login
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

          // 3. Logo ESK-PE (Fijo por encima de la tarjeta)
          Positioned(
            top: size.height * 0.08,
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

        // Widget auxiliar para no duplicar el diseño de los inputs
          Widget _buildTextField(
            String label, 
            TextInputType type, 
            String? Function(String?)? validator,
            {List<TextInputFormatter>? inputFormatters,
            TextCapitalization textCapitalization = TextCapitalization.none} // <--- NUEVO PARÁMETRO OPCIONAL
          ) {
            return TextFormField(
              keyboardType: type,
              validator: validator,
              inputFormatters: inputFormatters, // <--- ASIGNAMOS EL FILTRO AQUÍ
              textCapitalization: textCapitalization,
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