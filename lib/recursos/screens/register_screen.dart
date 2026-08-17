import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/pending_approval_screen.dart';
import 'package:prueba_eskpe/recursos/screens/verification_screen.dart';
import 'package:prueba_eskpe/recursos/colores.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // CONTROLADORES
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variables de control
  bool _esEmpresa = false;
  bool _obscurePassword = true;

  // Para viajeros: tipo de cédula (V / E)
  String _cedulaTipo = 'V';

  // Para empresas: tipo de documento ("Cédula de Identidad" o "RIF")
  String _tipoDocEmpresa = 'RIF';
  // Para empresas: prefijo de RIF (J, G, V, E)
  String _rifTipo = 'J';

  // RegEx de contraseña segura
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Retorna el límite superior de caracteres del documento de identidad según el tipo seleccionado.
  int get _maxLengthDocumento {
    if (!_esEmpresa) return 8;
    if (_tipoDocEmpresa == 'Cédula de Identidad') return 8;
    return 9;
  }

  /// Crea la cuenta en Firebase Auth y persiste la entidad estructurada (viajero o empresa) en Firestore.
  Future<void> _procesarRegistro() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.azulEskpe),
        ),
      );

      // A. Crear usuario en Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      if (_esEmpresa) {
        // --- FLUJO EMPRESA ---
        final String identificacion = _tipoDocEmpresa == 'RIF'
            ? '$_rifTipo-${_documentoController.text.trim()}'
            : '$_cedulaTipo-${_documentoController.text.trim()}';

        // Solo campos de empresa — sin apellidos, sin cédula de viajero
        final Map<String, dynamic> datosEmpresa = {
          'uid': uid,
          'nombres': _nombreController.text.trim(),
          'correo': _emailController.text.trim(),
          'contrasena': _passwordController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'tipo_documento': _tipoDocEmpresa,
          'documento': identificacion,
          'rol': 'empresa',
          'estado': 'pending',
          'fecha_registro': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set(datosEmpresa);

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Registro enviado. Tu cuenta será revisada por el equipo de ESK-PE.'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PendingApprovalScreen()),
          (route) => false,
        );
      } else {
        // --- FLUJO VIAJERO ---
        final String identificacion =
            '$_cedulaTipo-${_documentoController.text.trim()}';

        // Solo campos de viajero, sin nada de empresa
        final Map<String, dynamic> datosUsuario = {
          'uid': uid,
          'nombres': _nombreController.text.trim(),
          'apellidos': _apellidoController.text.trim(),
          'cedula': identificacion,
          'telefono': _telefonoController.text.trim(),
          'correo': _emailController.text.trim(),
          'contrasena': _passwordController.text.trim(),
          'rol': 'usuario',
          'estado': 'active',
          'fecha_registro': FieldValue.serverTimestamp(),
        };

        await userCredential.user?.sendEmailVerification();
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set(datosUsuario);

        if (!mounted) return;
        Navigator.pop(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationScreen(email: _emailController.text.trim()),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      String mensajeError = 'Ocurrió un error en el registro.';
      if (e.code == 'email-already-in-use')
        mensajeError = 'Este correo ya está registrado.';
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
      backgroundColor: AppColors.azulEskpe,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          RepaintBoundary(
            child: Container(
              width: size.width,
              height: size.height,
              color: AppColors.azulEskpe,
            ),
          ),
          RepaintBoundary(
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.15,
            left: 0,
            right: 0,
            bottom: -20,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
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
                          color: AppColors.azulEskpe,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // SELECTOR VIAJERO / EMPRESA
                      Container(
                        margin: const EdgeInsets.only(bottom: 25),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0ECFF),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _buildToggleOption("Viajero", !_esEmpresa, () {
                              setState(() {
                                _esEmpresa = false;
                                _documentoController.clear();
                              });
                            }),
                            _buildToggleOption("Empresa", _esEmpresa, () {
                              setState(() {
                                _esEmpresa = true;
                                _documentoController.clear();
                              });
                            }),
                          ],
                        ),
                      ),

                      // NOMBRE / RAZÓN SOCIAL
                      _buildTextField(
                        _esEmpresa ? "Razón Social / Nombre" : "Nombres",
                        TextInputType.name,
                        _nombreController,
                        (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _esEmpresa
                                ? 'Ingresa el nombre de la empresa'
                                : 'Ingresa tus nombres';
                          }
                          if (!_esEmpresa &&
                              !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$')
                                  .hasMatch(value)) {
                            return 'Los nombres no deben contener números';
                          }
                          return null;
                        },
                        inputFormatters: _esEmpresa
                            ? null
                            : [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))
                              ],
                        textCapitalization: TextCapitalization.words,
                        prefixIcon:
                            _esEmpresa ? Icons.business : Icons.person_outline,
                      ),

                      const SizedBox(height: 20),

                      // APELLIDOS (solo viajero)
                      if (!_esEmpresa) ...[
                        _buildTextField(
                          "Apellidos",
                          TextInputType.name,
                          _apellidoController,
                          (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Ingresa tus apellidos';
                            if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$')
                                .hasMatch(value))
                              return 'Los apellidos no deben contener números';
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+'))
                          ],
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // SELECTOR TIPO DOCUMENTO (solo empresa)
                      if (_esEmpresa) ...[
                        DropdownButtonFormField<String>(
                          value: _tipoDocEmpresa,
                          dropdownColor: Colors.white,
                          items: ['RIF', 'Cédula de Identidad']
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t,
                                        style: const TextStyle(
                                            color: AppColors.azulEskpe,
                                            fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _tipoDocEmpresa = val;
                                _documentoController.clear();
                              });
                            }
                          },
                          decoration: _inputDecoration(
                              'Tipo de documento', Icons.article_outlined),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // CAMPO DE DOCUMENTO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prefijo (J/G/V/E para RIF, V/E para cédula)
                          SizedBox(
                            width: 90,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('$_esEmpresa-$_tipoDocEmpresa'),
                              value: _esEmpresa
                                  ? (_tipoDocEmpresa == 'RIF'
                                      ? _rifTipo
                                      : _cedulaTipo)
                                  : _cedulaTipo,
                              dropdownColor: Colors.white,
                              items: (_esEmpresa && _tipoDocEmpresa == 'RIF'
                                      ? ['J', 'G', 'V', 'E']
                                      : ['V', 'E'])
                                  .map((tipo) => DropdownMenuItem(
                                        value: tipo,
                                        child: Text(tipo,
                                            style: const TextStyle(
                                                color: AppColors.azulEskpe,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    if (_esEmpresa &&
                                        _tipoDocEmpresa == 'RIF') {
                                      _rifTipo = val;
                                    } else {
                                      _cedulaTipo = val;
                                    }
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Tipo',
                                labelStyle: const TextStyle(
                                    color: Color(0xFF7A7A7A),
                                    fontWeight: FontWeight.w500),
                                filled: true,
                                fillColor: const Color(0xFFF7F7F9),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                    borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                    borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF4A3AFF), width: 2)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              _esEmpresa
                                  ? (_tipoDocEmpresa == 'RIF'
                                      ? 'Número RIF'
                                      : 'Cédula de Identidad')
                                  : 'Cédula de Identidad',
                              TextInputType.number,
                              _documentoController,
                              (value) {
                                if (value == null || value.isEmpty) {
                                  return _esEmpresa
                                      ? 'El documento es obligatorio'
                                      : 'La cédula es obligatoria';
                                }
                                if (_esEmpresa &&
                                    _tipoDocEmpresa == 'RIF' &&
                                    value.length < 9) {
                                  return 'El RIF debe tener 9 dígitos';
                                }
                                if ((!_esEmpresa ||
                                        _tipoDocEmpresa ==
                                            'Cédula de Identidad') &&
                                    value.length < 6) {
                                  return 'Debe tener al menos 6 dígitos';
                                }
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    _maxLengthDocumento),
                              ],
                              prefixIcon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // TELÉFONO
                      _buildTextField(
                        "Número telefónico",
                        TextInputType.phone,
                        _telefonoController,
                        (value) {
                          if (value == null || value.isEmpty)
                            return 'El número es obligatorio';
                          if (value.length < 11)
                            return 'Debe tener 11 dígitos (Ej: 04141234567)';
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        prefixIcon: Icons.phone_outlined,
                      ),

                      const SizedBox(height: 20),

                      // CORREO
                      _buildTextField(
                        "Correo electrónico",
                        TextInputType.emailAddress,
                        _emailController,
                        (value) {
                          if (value == null || value.isEmpty)
                            return 'El correo es obligatorio';
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value))
                            return 'Ingresa un correo válido';
                          return null;
                        },
                        prefixIcon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 20),

                      // CONTRASEÑA con validación estricta
                      TextFormField(
                        controller: _passwordController,
                        keyboardType: TextInputType.text,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333)),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'La contraseña es obligatoria';
                          if (!_passwordRegex.hasMatch(value)) {
                            return 'Debe tener 8+ caracteres, mayúscula,\nminúscula, número y carácter especial (@\$!%*?&)';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: const TextStyle(
                              color: Color(0xFF7A7A7A),
                              fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.azulEskpe),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.azulEskpe,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F7F9),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(
                                  color: AppColors.azulEskpe, width: 2)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(
                                  color: Colors.redAccent, width: 2)),
                          focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(
                                  color: Colors.redAccent, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // BOTÓN REGISTRARSE
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          gradient: const LinearGradient(
                            colors: [AppColors.azulEskpe, AppColors.azul1],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.azulEskpe.withValues(alpha: 0.4),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0)),
                          ),
                          child: const Text(
                            'REGISTRARSE',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(
                            text: "¿Ya tienes cuenta? ",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15),
                            children: [
                              TextSpan(
                                text: "Inicia sesión",
                                style: TextStyle(
                                  color: AppColors.azulEskpe,
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

          // Logo ESK-PE
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

  // Widget helper para el toggle Viajero/Empresa
  Widget _buildToggleOption(
      String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.azulEskpe : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.azulEskpe.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isActive ? Colors.white : AppColors.azulEskpe,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Decoración reutilizable para dropdowns
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          color: Color(0xFF7A7A7A), fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: AppColors.azulEskpe),
      filled: true,
      fillColor: const Color(0xFFF7F7F9),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide:
              const BorderSide(color: AppColors.azulEskpe, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  // Campo de texto reutilizable
  Widget _buildTextField(
    String label,
    TextInputType type,
    TextEditingController controller,
    String? Function(String?)? validator, {
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(
          fontWeight: FontWeight.w500, color: Color(0xFF333333)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Color(0xFF7A7A7A), fontWeight: FontWeight.w500),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.azulEskpe)
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F7F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide:
                const BorderSide(color: AppColors.azulEskpe, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}