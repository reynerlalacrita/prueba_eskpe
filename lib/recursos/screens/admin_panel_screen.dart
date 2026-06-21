import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Controllers para el formulario de Empresas
  final _formKeyEmpresa = GlobalKey<FormState>();
  final _nombreEmpresaController = TextEditingController();
  final _rifController = TextEditingController();
  final _contactoController = TextEditingController();

  // Controllers para el formulario de Lugares
  final _nombreLugarController = TextEditingController();
  final _descripcionLugarController = TextEditingController();
  final _rutaAssetLugarController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFCCCCCC), 
        appBar: AppBar(
          title: const Text('Panel de Administración ESK-PE', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.grey[800], 
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.beach_access), text: "Gestionar Lugares"),
              Tab(icon: Icon(Icons.business), text: "Gestionar Empresas"), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabLugares(),
            _buildTabGestionarEmpresas(), 
          ],
        ),
      ),
    );
  }

  // --- DIÁLOGO GLOBAL DE CONFIRMACIÓN PARA ELIMINAR ---
  void _mostrarDialogoEliminar(BuildContext context, String tipo, String nombre, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Eliminar $tipo"),
        content: Text("¿Seguro que quieres eliminar \"$nombre\"? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await docRef.delete(); // Borra directo en Firestore usando su referencia única
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$tipo eliminado correctamente")),
              );
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- PESTAÑA 1: GESTIONAR LUGARES (LISTA, EDICIÓN, CREACIÓN Y ELIMINACIÓN) ---
  // =========================================================================
  Widget _buildTabLugares() {
    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.azuleskpe,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _dialogoNuevoLugar(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('destinos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.azuleskpe));
          }

          final lugares = snapshot.data?.docs ?? [];

          if (lugares.isEmpty) {
            return const Center(child: Text("No hay destinos registrados todavía."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: lugares.length,
            itemBuilder: (context, index) {
              final doc = lugares[index];
              final data = doc.data() as Map<String, dynamic>;
              final nombreLugar = data['nombre'] ?? 'Sin nombre';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(data['rutaAsset'] ?? 'assets/placeholder.jpg'),
                  ),
                  title: Text(nombreLugar, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['descripcion'] ?? 'Sin descripción...', 
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  // 🛠️ SE MODIFICÓ AQUÍ: Fila con botones de Editar y Eliminar
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.purple),
                        onPressed: () => _dialogoEditarLugar(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _mostrarDialogoEliminar(context, "Destino", nombreLugar, doc.reference),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- DIÁLOGO PARA CREAR NUEVO DESTINO ---
  void _dialogoNuevoLugar() {
    _nombreLugarController.clear();
    _descripcionLugarController.clear();
    _rutaAssetLugarController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Añadir Nuevo Destino", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _nombreLugarController,
                decoration: const InputDecoration(labelText: "Nombre del Lugar", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descripcionLugarController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _rutaAssetLugarController,
                decoration: const InputDecoration(hintText: "Ej: assets/cayo_sombrero.jpg", labelText: "Ruta del Asset (Imagen)"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.azuleskpe),
                  onPressed: () async {
                    if (_nombreLugarController.text.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('destinos').add({
                        'nombre': _nombreLugarController.text,
                        'descripcion': _descripcionLugarController.text,
                        'rutaAsset': _rutaAssetLugarController.text.isEmpty ? 'assets/placeholder_playa.jpg' : _rutaAssetLugarController.text,
                        'etiquetas': [],
                        'fechaCreacion': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Destino añadido exitosamente")));
                    }
                  },
                  child: const Text("Agregar Destino", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIÁLOGO PARA EDITAR DESTINO ---
  void _dialogoEditarLugar(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final descController = TextEditingController(text: data['descripcion'] ?? 'Sin descripción..');
    final tagController = TextEditingController();
    List<String> tempTags = List<String>.from(data['etiquetas'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Editar ${data['nombre']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                const Text("Etiquetas:", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: tempTags.map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => setModalState(() => tempTags.remove(tag)),
                  )).toList(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: const InputDecoration(hintText: "Nueva etiqueta"),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.azuleskpe),
                      onPressed: () {
                        if (tagController.text.isNotEmpty) {
                          setModalState(() {
                            tempTags.add(tagController.text);
                            tagController.clear();
                          });
                        }
                      },
                    )
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.azuleskpe),
                    onPressed: () async {
                      await doc.reference.update({
                        'descripcion': descController.text,
                        'etiquetas': tempTags,
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Guardar Cambios", style: TextStyle(color: Colors.white)),
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

  // =========================================================================
  // --- PESTAÑA 2: GESTIONAR EMPRESAS (LISTA, CREACIÓN Y ELIMINACIÓN) ---
  // =========================================================================
  Widget _buildTabGestionarEmpresas() {
    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _dialogoNuevaEmpresa(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('empresas').snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error al cargar empresas"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purple));
          }

          final empresas = snapshot.data?.docs ?? [];

          if (empresas.isEmpty) {
            return const Center(child: Text("No hay empresas aliadas registradas."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: empresas.length,
            itemBuilder: (context, index) {
              final doc = empresas[index];
              final data = doc.data() as Map<String, dynamic>;
              final nombreEmpresa = data['nombre'] ?? 'Sin nombre';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.business, color: Colors.white),
                  ),
                  title: Text(nombreEmpresa, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("RIF: ${data['rif'] ?? 'S/R'}\nTel: ${data['contacto'] ?? 'S/T'}"),
                  isThreeLine: true, // Para darle espacio al subtítulo con salto de línea
                  // 🛠️ SE MODIFICÓ AQUÍ: Fila con icono verificado y botón de Eliminar
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.blueAccent),
                      const SizedBox(width: 5),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _mostrarDialogoEliminar(context, "Empresa Aliada", nombreEmpresa, doc.reference),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- DIÁLOGO EMERGENTE PARA NUEVA EMPRESA ---
  void _dialogoNuevaEmpresa() {
    _nombreEmpresaController.clear();
    _rifController.clear();
    _contactoController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20
        ),
        child: Form(
          key: _formKeyEmpresa,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Registrar Nueva Empresa Aliada", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreEmpresaController,
                  decoration: const InputDecoration(labelText: "Nombre de la Empresa", prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _rifController,
                  decoration: const InputDecoration(labelText: "RIF / ID Fiscal", prefixIcon: Icon(Icons.assignment_ind), border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _contactoController,
                  decoration: const InputDecoration(labelText: "Teléfono de Contacto", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () => _registrarEmpresa(),
                    child: const Text("REGISTRAR EMPRESA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _registrarEmpresa() async {
    if (_formKeyEmpresa.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('empresas').add({
        'nombre': _nombreEmpresaController.text,
        'rif': _rifController.text,
        'contacto': _contactoController.text,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Empresa registrada exitosamente")),
      );
    }
  }
}