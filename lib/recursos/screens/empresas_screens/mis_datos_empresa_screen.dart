import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:prueba_eskpe/recursos/colores.dart';

class MisDatosEmpresaScreen extends StatefulWidget {
  const MisDatosEmpresaScreen({super.key});

  @override
  State<MisDatosEmpresaScreen> createState() => _MisDatosEmpresaScreenState();
}

class _MisDatosEmpresaScreenState extends State<MisDatosEmpresaScreen> {
  final User? _usuario = FirebaseAuth.instance.currentUser;
  bool _cargandoDatos = true;
  bool _subiendoFoto = false;
  bool _subiendoPortada = false;
  bool _subiendoGaleria = false;

  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  String _fotoUrl = '';
  String _portadaUrl = '';
  List<String> _imagenesEmpresa = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

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
        _descripcionController.text = datos['descripcion'] ?? '';
        _telefonoController.text = datos['telefono'] ?? '';
        _cedulaController.text =
            datos['documento'] ?? datos['cedula'] ?? datos['rif'] ?? '';
        _fotoUrl = datos['fotoUrl'] ?? _usuario.photoURL ?? '';
        _portadaUrl = datos['portadaUrl'] ?? '';

        if (datos['imagenesEmpresa'] != null) {
          _imagenesEmpresa = List<String>.from(datos['imagenesEmpresa']);
        }
      } else {
        _nombreController.text = _usuario.displayName ?? '';
        _fotoUrl = _usuario.photoURL ?? '';
      }
    } catch (e) {
      debugPrint("Error al cargar datos de empresa: $e");
    } finally {
      if (mounted) {
        setState(() => _cargandoDatos = false);
      }
    }
  }

  // 1. LÓGICA PARA CAMBIAR FOTO DE PERFIL (Logo de empresa)
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
      File archivoOriginal = File(imagen.path);
      String uid = _usuario.uid;

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.webp';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            archivoOriginal.path,
            targetPath,
            format: CompressFormat.webp,
            quality: 80,
          );

      if (compressedFile == null)
        throw Exception("Error al comprimir la imagen");
      File archivoAsubir = File(compressedFile.path);

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('perfiles')
          .child('$uid.webp');

      UploadTask uploadTask = ref.putFile(archivoAsubir);
      TaskSnapshot snapshot = await uploadTask;
      String urlDescarga = await snapshot.ref.getDownloadURL();

      await _usuario.updatePhotoURL(urlDescarga);
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'fotoUrl': urlDescarga,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _fotoUrl = urlDescarga;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo de empresa actualizado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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

  // 1.2 LÓGICA PARA CAMBIAR FOTO DE PORTADA
  Future<void> _seleccionarYSubirPortada() async {
    if (_usuario == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (imagen == null) return;

    setState(() => _subiendoPortada = true);

    try {
      File archivoOriginal = File(imagen.path);
      String uid = _usuario.uid;

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.webp';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            archivoOriginal.path,
            targetPath,
            format: CompressFormat.webp,
            quality: 85,
          );

      if (compressedFile == null)
        throw Exception("Error al comprimir la portada");
      File archivoAsubir = File(compressedFile.path);

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('portadas')
          .child('${uid}_portada.webp');

      UploadTask uploadTask = ref.putFile(archivoAsubir);
      TaskSnapshot snapshot = await uploadTask;
      String urlDescarga = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'portadaUrl': urlDescarga,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _portadaUrl = urlDescarga;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de portada actualizada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la portada: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _subiendoPortada = false);
      }
    }
  }

  // 1.5 LÓGICA PARA SELECCIONAR MULTIPLES IMÁGENES
  Future<void> _seleccionarImagenesGaleria() async {
    if (_usuario == null) return;

    final ImagePicker picker = ImagePicker();
    final List<XFile> imagenes = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (imagenes.isEmpty) return;

    // Calcular cuántas podemos subir
    int disponibles = 8 - _imagenesEmpresa.length;
    if (disponibles <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya has alcanzado el límite de 8 fotos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<XFile> imagenesASubir = imagenes.take(disponibles).toList();

    setState(() => _subiendoGaleria = true);

    try {
      String uid = _usuario.uid;
      List<String> nuevasUrls = [];

      for (var img in imagenesASubir) {
        File archivoOriginal = File(img.path);
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();

        final tempDir = await getTemporaryDirectory();
        final targetPath = '${tempDir.path}/$fileName.webp';

        final XFile? compressedFile =
            await FlutterImageCompress.compressAndGetFile(
              archivoOriginal.path,
              targetPath,
              format: CompressFormat.webp,
              quality: 80,
            );

        if (compressedFile == null)
          throw Exception("Error al comprimir imagen de la galería");
        File archivoAsubir = File(compressedFile.path);

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('empresas_imagenes')
            .child(uid)
            .child('$fileName.webp');

        UploadTask uploadTask = ref.putFile(archivoAsubir);
        TaskSnapshot snapshot = await uploadTask;
        String urlDescarga = await snapshot.ref.getDownloadURL();
        nuevasUrls.add(urlDescarga);
      }

      _imagenesEmpresa.addAll(nuevasUrls);

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'imagenesEmpresa': _imagenesEmpresa,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${nuevasUrls.length} imagen(es) subidas con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imágenes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _subiendoGaleria = false);
      }
    }
  }

  Future<void> _eliminarImagenGaleria(int index) async {
    if (_usuario == null) return;

    String urlEliminar = _imagenesEmpresa[index];

    setState(() {
      _imagenesEmpresa.removeAt(index);
    });

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_usuario.uid)
          .set({'imagenesEmpresa': _imagenesEmpresa}, SetOptions(merge: true));

      try {
        Reference ref = FirebaseStorage.instance.refFromURL(urlEliminar);
        await ref.delete();
      } catch (e) {
        debugPrint("Error eliminando del storage: $e");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen eliminada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 2. LÓGICA PARA CAMBIAR CORREO
  Future<void> _mostrarDialogoEditarCorreo() async {
    final TextEditingController nuevoCorreoCtrl = TextEditingController(
      text: _usuario?.email ?? '',
    );
    final TextEditingController passwordCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Editar Correo Electrónico",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A4F),
            ),
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
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF1E2A4F),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña Actual (Re-autenticación)",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF1E2A4F),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azuleskpe,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                String nuevoCorreo = nuevoCorreoCtrl.text.trim();
                String pass = passwordCtrl.text.trim();

                if (nuevoCorreo.isEmpty || pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa los campos.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                _procesarCambioCorreo(nuevoCorreo, pass);
              },
              child: const Text(
                "Guardar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarCambioCorreo(
    String nuevoCorreo,
    String contrasenaActual,
  ) async {
    if (_usuario == null) return;
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _usuario.email!,
        password: contrasenaActual,
      );
      await _usuario.reauthenticateWithCredential(credential);
      await _usuario.verifyBeforeUpdateEmail(nuevoCorreo);
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_usuario.uid)
          .update({'correo': nuevoCorreo});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se ha enviado un correo de confirmación al nuevo email.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Cambiar Contraseña",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A4F),
            ),
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
                    prefixIcon: const Icon(
                      Icons.lock_clock_outlined,
                      color: Color(0xFF1E2A4F),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nuevaPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Nueva Contraseña",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF1E2A4F),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azuleskpe,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                String actualPass = actualPassCtrl.text.trim();
                String nuevaPass = nuevaPassCtrl.text.trim();
                if (actualPass.isEmpty || nuevaPass.isEmpty) return;
                if (nuevaPass.length < 6) return;
                Navigator.pop(dialogContext);
                _procesarCambioPassword(actualPass, nuevaPass);
              },
              child: const Text(
                "Actualizar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarCambioPassword(
    String actualPassword,
    String nuevaPassword,
  ) async {
    if (_usuario == null || _usuario.email == null) return;
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _usuario.email!,
        password: actualPassword,
      );
      await _usuario.reauthenticateWithCredential(credential);
      await _usuario.updatePassword(nuevaPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Contraseña actualizada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 4. GUARDAR CAMBIOS EN FIRESTORE
  Future<void> _guardarDatosEmpresa() async {
    if (_usuario == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_usuario.uid)
          .set({
            'nombres': _nombreController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'telefono': _telefonoController.text.trim(),
          }, SetOptions(merge: true));

      await _usuario.updateDisplayName(_nombreController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos de empresa guardados correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blancofondo,
      appBar: AppBar(
        title: const Text(
          "Datos de la Empresa",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  // PORTADA Y LOGO DE EMPRESA
                  _buildCard(
                    child: Column(
                      children: [
                        RepaintBoundary(
                          child: SizedBox(
                            height: 200,
                            child: Stack(
                              children: [
                                // 1. FOTO DE PORTADA
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 160,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _portadaUrl.isNotEmpty
                                            ? Image.network(
                                                _portadaUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey.shade300,
                                                child: const Center(
                                                  child: Text(
                                                    "Sin Foto de Portada",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        if (_subiendoPortada)
                                          Container(
                                            color: Colors.black45,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Botón para editar portada
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: InkWell(
                                    onTap: _subiendoPortada
                                        ? null
                                        : _seleccionarYSubirPortada,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            "Portada",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 2. LOGO DE LA EMPRESA (Abajo a la izquierda)
                                Positioned(
                                  bottom: 0,
                                  left: 20,
                                  child: Stack(
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
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage: _fotoUrl.isNotEmpty
                                              ? NetworkImage(_fotoUrl)
                                                    as ImageProvider
                                              : const AssetImage(
                                                  'assets/sinfoto.jpg',
                                                ),
                                        ),
                                      ),
                                      if (_subiendoFoto)
                                        Container(
                                          width: 88,
                                          height: 88,
                                          decoration: const BoxDecoration(
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
                                          onTap: _subiendoFoto
                                              ? null
                                              : _seleccionarYSubirFoto,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF1E2A4F),
                                              shape: BoxShape.circle,
                                              border: Border(
                                                top: BorderSide(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                bottom: BorderSide(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                left: BorderSide(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                right: BorderSide(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Personaliza tu perfil con una foto de portada y tu logo.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // INFORMACIÓN DE LA EMPRESA
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Información Principal",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A4F),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          label: "Nombre de la Empresa",
                          icon: Icons.business,
                          controller: _nombreController,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          label: "Descripción",
                          icon: Icons.description_outlined,
                          controller: _descripcionController,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          label: "Cédula / RIF",
                          icon: Icons.badge_outlined,
                          controller: _cedulaController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          label: "Teléfono (WhatsApp)",
                          icon: Icons.phone_outlined,
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azuleskpe,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _guardarDatosEmpresa,
                            child: const Text(
                              "Guardar Información",
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

                  // CARRUSEL DE IMAGENES DE LA EMPRESA
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Fotos de la Empresa",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2A4F),
                              ),
                            ),
                            Text(
                              "${_imagenesEmpresa.length}/8",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        if (_imagenesEmpresa.isNotEmpty)
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 180,
                              enableInfiniteScroll: false,
                              enlargeCenterPage: true,
                            ),
                            items: _imagenesEmpresa.asMap().entries.map((
                              entry,
                            ) {
                              int index = entry.key;
                              String url = entry.value;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: InkWell(
                                      onTap: () =>
                                          _eliminarImagenGaleria(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                        else
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "No has subido fotos promocionales.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),

                        const SizedBox(height: 15),
                        if (_subiendoGaleria)
                          const Center(child: CircularProgressIndicator())
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1E2A4F),
                                side: const BorderSide(
                                  color: Color(0xFF1E2A4F),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _imagenesEmpresa.length >= 8
                                  ? null
                                  : _seleccionarImagenesGaleria,
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: const Text(
                                "Subir Fotos",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SEGURIDAD Y ACCESO
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF1E2A4F),
                          ),
                          title: const Text(
                            "Correo electrónico",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _usuario?.email ?? "No registrado",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF1E2A4F),
                            ),
                            onPressed: _mostrarDialogoEditarCorreo,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF1E2A4F),
                          ),
                          title: const Text(
                            "Contraseña",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            "********",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF1E2A4F),
                            ),
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
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(
        color: readOnly ? Colors.grey.shade700 : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: const Color(0xFF1E2A4F))
            : Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Icon(icon, color: const Color(0xFF1E2A4F)),
              ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF7F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        counterText: "",
      ),
    );
  }
}
