import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  void _cerrarSesion(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que quieres salir?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              "Cerrar Sesión",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.blancofondo,
        appBar: AppBar(
          title: const Text(
            'Panel de Administración',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor:
              AppColors.azuleskpe, // Modificado al color azul eskpe
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Cerrar Sesión",
              onPressed: () => _cerrarSesion(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.beach_access), text: "Destinos"),
              Tab(icon: Icon(Icons.business), text: "Empresas"),
              Tab(icon: Icon(Icons.people), text: "Usuarios"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [TabDestinos(), TabEmpresas(), TabUsuarios()],
        ),
      ),
    );
  }
}

// =========================================================================
// --- COMPONENTES AUXILIARES ---
// =========================================================================

// Widget reutilizable para la barra de búsqueda
class BarraBusqueda extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const BarraBusqueda({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: Colors.white,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 15,
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// --- TAB 1: DESTINOS ---
// =========================================================================
class TabDestinos extends StatefulWidget {
  const TabDestinos({super.key});
  @override
  State<TabDestinos> createState() => _TabDestinosState();
}

class _TabDestinosState extends State<TabDestinos> {
  final _nombreLugarController = TextEditingController();
  final _descripcionLugarController = TextEditingController();
  bool _subiendoImagen = false;
  File? _imagenSeleccionada;
  String _searchQuery = ''; // Variable de búsqueda

  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = File(imagen.path);
      });
    }
  }

  Future<String?> _subirImagenAFirebase(File imagen) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.webp';

      var result = await FlutterImageCompress.compressAndGetFile(
        imagen.absolute.path,
        targetPath,
        quality: 80,
        format: CompressFormat.webp,
      );

      if (result == null) return null;

      File fileToUpload = File(result.path);

      String fileName =
          'destinos/${DateTime.now().millisecondsSinceEpoch}.webp';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(fileToUpload);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      return null;
    }
  }

  void _dialogoDestino({DocumentSnapshot? doc}) {
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      _nombreLugarController.text = data['nombre'] ?? '';
      _descripcionLugarController.text = data['descripcion'] ?? '';
    } else {
      _nombreLugarController.clear();
      _descripcionLugarController.clear();
    }
    _imagenSeleccionada = null;
    _subiendoImagen = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 25,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc == null ? "Añadir Nuevo Destino" : "Editar Destino",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azuleskpe,
                  ),
                ),
                const SizedBox(height: 20),

                // Selector de Imagen
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      await _seleccionarImagen();
                      setModalState(() {});
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _imagenSeleccionada != null
                            ? DecorationImage(
                                image: FileImage(_imagenSeleccionada!),
                                fit: BoxFit.cover,
                              )
                            : (doc != null &&
                                  (doc.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >)['rutaAsset'] !=
                                      null)
                            ? DecorationImage(
                                image:
                                    ((doc.data()
                                                    as Map<
                                                      String,
                                                      dynamic
                                                    >)['rutaAsset']
                                                .toString()
                                                .startsWith('http')
                                            ? NetworkImage(
                                                (doc.data()
                                                    as Map<
                                                      String,
                                                      dynamic
                                                    >)['rutaAsset'],
                                              )
                                            : AssetImage(
                                                (doc.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >)['rutaAsset']
                                                        .toString()
                                                        .isNotEmpty
                                                    ? (doc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >)['rutaAsset']
                                                    : 'assets/sinfoto.jpg',
                                              ))
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          _imagenSeleccionada == null &&
                              (doc == null ||
                                  (doc.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >)['rutaAsset'] ==
                                      null ||
                                  (doc.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >)['rutaAsset'] ==
                                      '')
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Toca para subir una foto",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nombreLugarController,
                  decoration: InputDecoration(
                    labelText: "Nombre del Lugar",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _descripcionLugarController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Descripción",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azuleskpe,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _subiendoImagen
                        ? null
                        : () async {
                            if (_nombreLugarController.text.trim().isEmpty)
                              return;

                            setModalState(() => _subiendoImagen = true);

                            String? finalImageUrl;
                            if (_imagenSeleccionada != null) {
                              finalImageUrl = await _subirImagenAFirebase(
                                _imagenSeleccionada!,
                              );
                            } else if (doc != null) {
                              finalImageUrl =
                                  (doc.data()
                                      as Map<String, dynamic>)['rutaAsset'];
                            }

                            if (doc == null) {
                              await FirebaseFirestore.instance
                                  .collection('destinos')
                                  .add({
                                    'nombre': _nombreLugarController.text
                                        .trim(),
                                    'descripcion': _descripcionLugarController
                                        .text
                                        .trim(),
                                    'rutaAsset':
                                        finalImageUrl ?? 'assets/sinfoto.jpg',
                                    'etiquetas': [],
                                    'fechaCreacion':
                                        FieldValue.serverTimestamp(),
                                  });
                            } else {
                              await doc.reference.update({
                                'nombre': _nombreLugarController.text.trim(),
                                'descripcion': _descripcionLugarController.text
                                    .trim(),
                                if (finalImageUrl != null)
                                  'rutaAsset': finalImageUrl,
                              });
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Destino guardado exitosamente",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: _subiendoImagen
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            doc == null ? "Agregar Destino" : "Guardar Cambios",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _eliminarDestino(DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Eliminar Destino"),
        content: const Text(
          "¿Seguro que quieres eliminar este destino? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await docRef.delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Destino eliminado"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.azuleskpe,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _dialogoDestino(),
      ),
      body: Column(
        children: [
          BarraBusqueda(
            hintText: "Buscar destinos...",
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('destinos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text("No hay destinos."));

                // Filtrar por búsqueda
                var docsFiltrados = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '')
                      .toString()
                      .toLowerCase();
                  return nombre.contains(_searchQuery);
                }).toList();

                if (docsFiltrados.isEmpty)
                  return const Center(
                    child: Text("No se encontraron resultados."),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docsFiltrados.length,
                  itemBuilder: (context, index) {
                    final doc = docsFiltrados[index];
                    final data = doc.data() as Map<String, dynamic>;
                    String rutaAsset =
                        data['rutaAsset'] ?? 'assets/sinfoto.jpg';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: rutaAsset.startsWith('http')
                                ? Image.network(rutaAsset, fit: BoxFit.cover)
                                : Image.asset(
                                    rutaAsset.isNotEmpty
                                        ? rutaAsset
                                        : 'assets/sinfoto.jpg',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        title: Text(
                          data['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.azuleskpe,
                          ),
                        ),
                        subtitle: Text(
                          data['descripcion'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () => _dialogoDestino(doc: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarDestino(doc.reference),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// --- TAB 2: EMPRESAS ---
// =========================================================================
class TabEmpresas extends StatefulWidget {
  const TabEmpresas({super.key});

  @override
  State<TabEmpresas> createState() => _TabEmpresasState();
}

class _TabEmpresasState extends State<TabEmpresas> {
  String _searchQuery = '';

  Future<void> _abrirWhatsApp(BuildContext context, String numero) async {
    if (numero.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No hay número registrado")));
      return;
    }
    String cleanNumber = numero.replaceAll(RegExp(r'\D'), '');
    if (!cleanNumber.startsWith('58') &&
        cleanNumber.length == 11 &&
        cleanNumber.startsWith('0')) {
      cleanNumber = '58${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('58') && cleanNumber.length == 10) {
      cleanNumber = '58$cleanNumber';
    }
    final Uri url = Uri.parse("https://wa.me/$cleanNumber");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }

  void _cambiarEstado(DocumentReference docRef, String nuevoEstado) {
    docRef.update({'estado': nuevoEstado});
  }

  void _eliminarUsuario(
    BuildContext context,
    DocumentReference docRef,
    String nombre,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Eliminar Empresa"),
        content: Text("¿Seguro que quieres eliminar a $nombre?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              docRef.delete();
              Navigator.pop(context);
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BarraBusqueda(
          hintText: "Buscar empresas...",
          onChanged: (val) {
            setState(() {
              _searchQuery = val.toLowerCase();
            });
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .where('rol', isEqualTo: 'empresa')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(child: Text("No hay empresas."));

              var docsFiltrados = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nombre =
                    (data['nombres'] ??
                            data['razon_social'] ??
                            data['nombre'] ??
                            '')
                        .toString()
                        .toLowerCase();
                final rif = (data['rif'] ?? data['documento'] ?? '')
                    .toString()
                    .toLowerCase();
                final email = (data['email'] ?? data['correo'] ?? '')
                    .toString()
                    .toLowerCase();
                return nombre.contains(_searchQuery) ||
                    rif.contains(_searchQuery) ||
                    email.contains(_searchQuery);
              }).toList();

              if (docsFiltrados.isEmpty)
                return const Center(
                  child: Text("No se encontraron resultados."),
                );

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: docsFiltrados.length,
                itemBuilder: (context, index) {
                  final doc = docsFiltrados[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String estado = data['estado'] ?? 'pending';
                  final String foto =
                      data['fotoUrl'] ??
                      data['logoUrl'] ??
                      data['imagenPerfil'] ??
                      '';
                  final String nombre =
                      data['nombres'] ??
                      data['razon_social'] ??
                      data['nombre'] ??
                      'Sin nombre';
                  final String telefono =
                      data['telefono'] ?? data['contacto'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: foto.isNotEmpty
                                    ? NetworkImage(foto)
                                    : null,
                                child: foto.isEmpty
                                    ? const Icon(
                                        Icons.business,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "ID/RIF: ${data['documento'] ?? data['rif'] ?? data['cedula'] ?? 'S/R'}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "Correo: ${data['email'] ?? data['correo'] ?? 'S/C'}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: estado == 'active'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  estado.toUpperCase(),
                                  style: TextStyle(
                                    color: estado == 'active'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                ),
                                onSelected: (val) {
                                  if (val == 'active')
                                    _cambiarEstado(doc.reference, 'active');
                                  if (val == 'pending')
                                    _cambiarEstado(doc.reference, 'pending');
                                  if (val == 'delete')
                                    _eliminarUsuario(
                                      context,
                                      doc.reference,
                                      nombre,
                                    );
                                },
                                itemBuilder: (context) => [
                                  if (estado != 'active')
                                    const PopupMenuItem(
                                      value: 'active',
                                      child: Text(
                                        "Aprobar Empresa",
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  if (estado != 'pending')
                                    const PopupMenuItem(
                                      value: 'pending',
                                      child: Text(
                                        "Poner en Pendiente",
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      "Eliminar",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    telefono.isNotEmpty
                                        ? telefono
                                        : 'Sin teléfono',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              if (telefono.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () =>
                                      _abrirWhatsApp(context, telefono),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    "WhatsApp",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// --- TAB 3: USUARIOS ---
// =========================================================================
class TabUsuarios extends StatefulWidget {
  const TabUsuarios({super.key});

  @override
  State<TabUsuarios> createState() => _TabUsuariosState();
}

class _TabUsuariosState extends State<TabUsuarios> {
  String _searchQuery = '';

  void _eliminarUsuario(
    BuildContext context,
    DocumentReference docRef,
    String nombre,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Eliminar Usuario"),
        content: Text("¿Seguro que quieres eliminar al usuario $nombre?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              docRef.delete();
              Navigator.pop(context);
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BarraBusqueda(
          hintText: "Buscar usuarios...",
          onChanged: (val) {
            setState(() {
              _searchQuery = val.toLowerCase();
            });
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .where('rol', isEqualTo: 'usuario')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(child: Text("No hay usuarios."));

              var docsFiltrados = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nombre = (data['nombres'] ?? data['nombre'] ?? '')
                    .toString()
                    .toLowerCase();
                final email = (data['email'] ?? data['correo'] ?? '')
                    .toString()
                    .toLowerCase();
                final cedula = (data['cedula'] ?? data['documento'] ?? '')
                    .toString()
                    .toLowerCase();
                return nombre.contains(_searchQuery) ||
                    email.contains(_searchQuery) ||
                    cedula.contains(_searchQuery);
              }).toList();

              if (docsFiltrados.isEmpty)
                return const Center(
                  child: Text("No se encontraron resultados."),
                );

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: docsFiltrados.length,
                itemBuilder: (context, index) {
                  final doc = docsFiltrados[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String foto =
                      data['fotoUrl'] ?? data['imagenPerfil'] ?? '';
                  final String nombre =
                      data['nombres'] ?? data['nombre'] ?? 'Sin nombre';
                  final String cedula =
                      data['cedula'] ?? data['documento'] ?? 'S/C';
                  final String telefono = data['telefono'] ?? 'S/T';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: foto.isNotEmpty
                            ? NetworkImage(foto)
                            : null,
                        child: foto.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            "Cédula: $cedula",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Teléfono: $telefono",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Correo: ${data['email'] ?? data['correo'] ?? 'S/C'}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _eliminarUsuario(context, doc.reference, nombre),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
