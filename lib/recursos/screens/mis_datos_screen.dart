import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- Importante para los formatters
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MisDatosScreen extends StatefulWidget {
  const MisDatosScreen({super.key});

  @override
  State<MisDatosScreen> createState() => _MisDatosScreenState();
}

class _MisDatosScreenState extends State<MisDatosScreen> {
  final User? _usuario = FirebaseAuth.instance.currentUser;
  bool _cargandoDatos = true;
  bool _subiendoFoto = false;

  // Controladores de texto para los datos de Firestore
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  String _fotoUrl = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  // Cargar datos actuales desde Firestore y Firebase Auth
  Future<void> _cargarDatosUsuario() async {
    if (_usuario == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_usuario.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> datos = doc.data() as Map<String, dynamic>;
        _nombreController.text = datos['nombres'] ?? _usuario.displayName ?? '';
        _apellidoController.text = datos['apellidos'] ?? '';
        _telefonoController.text = datos['telefono'] ?? '';
        _cedulaController.text = datos['cedula'] ?? datos['rif'] ?? '';
        _fotoUrl = datos['fotoUrl'] ?? _usuario.photoURL ?? '';
      } else {
        _nombreController.text = _usuario.displayName ?? '';
        _fotoUrl = _usuario.photoURL ?? '';
      }
    } catch (e) {
      debugPrint("Error al cargar datos del usuario: $e");
    } finally {
      if (mounted) {
        setState(() => _cargandoDatos = false);
      }
    }
  }

  // 1. LÓGICA PARA CAMBIAR FOTO DE PERFIL (image_picker + Firebase Storage)
  Future<void> _seleccionarYSubirFoto() async {
    if (_usuario == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (imagen == null) return;

    setState(() => _subiendoFoto = true);

    try {
      File archivo = File(imagen.path);
      String uid = _usuario.uid;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('perfiles')
          .child('$uid.jpg');

      UploadTask uploadTask = ref.putFile(archivo);
      TaskSnapshot snapshot = await uploadTask;
      String urlDescarga = await snapshot.ref.getDownloadURL();

      // Actualizar fotoURL en Auth
      await _usuario.updatePhotoURL(urlDescarga);

      // Actualizar fotoUrl en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
        {'fotoUrl': urlDescarga},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _fotoUrl = urlDescarga;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil actualizada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error al subir foto: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _subiendoFoto = false);
      }
    }
  }

  // 2. LÓGICA PARA CAMBIAR CORREO ELECTRÓNICO
  Future<void> _mostrarDialogoEditarCorreo() async {
    final TextEditingController nuevoCorreoCtrl =
        TextEditingController(text: _usuario?.email ?? '');
    final TextEditingController passwordCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Editar Correo Electrónico",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nuevoCorreoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Nuevo Correo",
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: Color(0xFF1E2A4F)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña Actual (Re-autenticación)",
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF1E2A4F)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2A4F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                String nuevoCorreo = nuevoCorreoCtrl.text.trim();
                String pass = passwordCtrl.text.trim();

                if (nuevoCorreo.isEmpty || pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor completa los campos.'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                _procesarCambioCorreo(nuevoCorreo, pass);
              },
              child: const Text("Guardar",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarCambioCorreo(
      String nuevoCorreo, String contrasenaActual) async {
    if (_usuario == null) return;

    try {
      // Re-autenticar al usuario por seguridad
      AuthCredential credential = EmailAuthProvider.credential(
        email: _usuario.email!,
        password: contrasenaActual,
      );

      await _usuario.reauthenticateWithCredential(credential);

      // Intentar actualizar correo en Firebase Auth
      await _usuario.verifyBeforeUpdateEmail(nuevoCorreo);

      // Actualizar correo en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_usuario.uid)
          .update({'correo': nuevoCorreo});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se ha enviado un correo de confirmación al nuevo email. Revisa tu bandeja.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Error al actualizar correo.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'La contraseña actual es incorrecta.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'El nuevo correo ya está en uso por otra cuenta.';
      } else if (e.code == 'invalid-email') {
        msg = 'El correo ingresado no es válido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 3. LÓGICA PARA CAMBIAR CONTRASEÑA
  Future<void> _mostrarDialogoEditarPassword() async {
    final TextEditingController actualPassCtrl = TextEditingController();
    final TextEditingController nuevaPassCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Cambiar Contraseña",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: actualPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña Actual",
                    prefixIcon: const Icon(Icons.lock_clock_outlined,
                        color: Color(0xFF1E2A4F)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nuevaPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Nueva Contraseña",
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF1E2A4F)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2A4F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                String actualPass = actualPassCtrl.text.trim();
                String nuevaPass = nuevaPassCtrl.text.trim();

                if (actualPass.isEmpty || nuevaPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor ingresa ambas contraseñas.'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }

                if (nuevaPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('La nueva contraseña debe tener al menos 6 caracteres.'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                _procesarCambioPassword(actualPass, nuevaPass);
              },
              child: const Text("Actualizar",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarCambioPassword(
      String actualPassword, String nuevaPassword) async {
    if (_usuario == null || _usuario.email == null) return;

    try {
      // 1. Re-autenticación
      AuthCredential credential = EmailAuthProvider.credential(
        email: _usuario.email!,
        password: actualPassword,
      );

      await _usuario.reauthenticateWithCredential(credential);

      // 2. Actualizar la contraseña
      await _usuario.updatePassword(nuevaPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Contraseña actualizada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Error al cambiar contraseña.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'La contraseña actual es incorrecta.';
      } else if (e.code == 'weak-password') {
        msg = 'La nueva contraseña es muy débil.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 4. GUARDAR CAMBIOS DE NOMBRES Y TELÉFONO EN FIRESTORE
  Future<void> _guardarDatosPersonales() async {
    if (_usuario == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_usuario.uid)
          .set({
        'nombres': _nombreController.text.trim(),
        'apellidos': _apellidoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
      }, SetOptions(merge: true));

      // Actualizar también displayName en Firebase Auth
      await _usuario.updateDisplayName(
        '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos guardados correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A4F),
        elevation: 0,
        title: const Text(
          "Mis Datos",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargandoDatos
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // CARD 1: EDICIÓN DE FOTO DE PERFIL
                  _buildCard(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _fotoUrl.isNotEmpty
                                    ? NetworkImage(_fotoUrl) as ImageProvider
                                    : const AssetImage(
                                        'assets/placeholder_user.jpg',
                                      ),
                              ),
                            ),
                            if (_subiendoFoto)
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _subiendoFoto ? null : _seleccionarYSubirFoto,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E2A4F),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Presiona la cámara para cambiar foto",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CARD 2: INFORMACIÓN PERSONAL
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Información Personal",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A4F),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          label: "Nombres",
                          icon: Icons.person_outline,
                          controller: _nombreController,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          label: "Apellidos",
                          icon: Icons.person_outline,
                          controller: _apellidoController,
                        ),
                        const SizedBox(height: 15),
                        // CÉDULA: Se mantiene bloqueada (readOnly: true)
                        _buildInputField(
                          label: "Cédula / RIF",
                          icon: Icons.badge_outlined,
                          controller: _cedulaController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 15),
                        // TELÉFONO: Limitado a 11 dígitos numéricos máximo
                        _buildInputField(
                          label: "Teléfono",
                          icon: Icons.phone_outlined,
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          maxLength: 11, // Límite de caracteres
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Solo números
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2A4F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _guardarDatosPersonales,
                            child: const Text(
                              "Guardar Cambios Personales",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CARD 3: SEGURIDAD Y ACCESO (Correo y Contraseña)
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Seguridad y Credenciales",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A4F),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Item de Correo Electrónico
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.email_outlined,
                              color: Color(0xFF1E2A4F)),
                          title: const Text(
                            "Correo electrónico",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          subtitle: Text(
                            _usuario?.email ?? "No registrado",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFF1E2A4F)),
                            onPressed: _mostrarDialogoEditarCorreo,
                          ),
                        ),
                        const Divider(),

                        // Item de Contraseña
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lock_outline,
                              color: Color(0xFF1E2A4F)),
                          title: const Text(
                            "Contraseña",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          subtitle: const Text(
                            "********",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFF1E2A4F)),
                            onPressed: _mostrarDialogoEditarPassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Contenedor modular de tarjeta blanca con sombra
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: readOnly ? Colors.grey.shade700 : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF1E2A4F)),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF7F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Si no quieres que aparezca el contador numérico de caracteres abajo (ej. "0/11"), 
        // puedes descomentar la siguiente línea:
         counterText: "", 
      ),
    );
  }
}
