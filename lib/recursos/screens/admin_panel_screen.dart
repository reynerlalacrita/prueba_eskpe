import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKeyEmpresa = GlobalKey<FormState>();
  final _formKeyViaje = GlobalKey<FormState>();

  // Controladores para Empresas
  final _nombreEmpresaCtrl = TextEditingController();
  File? _imagenEmpresa;

  // Controladores para Viajes / Prontos
  final _nombreViajeCtrl = TextEditingController();
  final _precioViajeCtrl = TextEditingController();
  final _fechaViajeCtrl = TextEditingController();
  File? _imagenViaje;

  final ImagePicker _picker = ImagePicker();

  // Función para seleccionar foto desde la galería del celular
    Future<void> _seleccionarImagen(bool esEmpresa) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          if (esEmpresa) {
            _imagenEmpresa = File(image.path);
          } else {
            _imagenViaje = File(image.path);
          }
        });
      }
    } catch (e) {
      print("Error al abrir galería: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dos pestañas: Empresas y Viajes
      child: Scaffold(
        backgroundColor: const Color(0xFFEAEAEA),
        appBar: AppBar(
          title: const Text('Panel de Administrador', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF2E16D1),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.business), text: "Nueva Empresa"),
              Tab(icon: Icon(Icons.card_travel), text: "Nuevo Viaje"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: FORMULARIO EMPRESAS
            _buildFormularioEmpresa(),
            
            // PESTAÑA 2: FORMULARIO VIAJES
            _buildFormularioViaje(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioEmpresa() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25.0),
      child: Form(
        key: _formKeyEmpresa,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Registrar Nueva Empresa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(_nombreEmpresaCtrl, "Nombre de la Empresa", TextInputType.text),
            const SizedBox(height: 25),
            
            // Selector de Imagen
            const Text("Imagen de la Empresa (Logo/Fachada)", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _seleccionarImagen(true),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2E16D1), width: 2),
                ),
                child: _imagenEmpresa == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Color(0xFF2E16D1))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        child: Image.file(_imagenEmpresa!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            _buildBotonPublicar(() {
              if (_formKeyEmpresa.currentState!.validate() && _imagenEmpresa != null) {
                // Aquí envías los datos de la nueva empresa
                Navigator.pop(context, {
                  'tipo': 'empresa',
                  'nombre': _nombreEmpresaCtrl.text,
                  'imagenFile': _imagenEmpresa,
                });
              } else if (_imagenEmpresa == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, selecciona una imagen')),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioViaje() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25.0),
      child: Form(
        key: _formKeyViaje,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Publicar Nuevo Viaje (Prontos)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(_nombreViajeCtrl, "Destino (Ej: Cayo Sombrero)", TextInputType.text),
            const SizedBox(height: 20),
            _buildTextField(_precioViajeCtrl, "Precio (Ej: 20.00)", TextInputType.number),
            const SizedBox(height: 20),
            _buildTextField(_fechaViajeCtrl, "Fecha (Ej: 26 de Noviembre)", TextInputType.text),
            const SizedBox(height: 25),
            
            // Selector de Imagen Rectangular para Tarjetas
            const Text("Imagen de Portada del Destino", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _seleccionarImagen(false),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2E16D1), width: 2),
                ),
                child: _imagenViaje == null
                    ? const Icon(Icons.add_photo_alternate, size: 50, color: Color(0xFF2E16D1))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_imagenViaje!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            _buildBotonPublicar(() {
              if (_formKeyEmpresa.currentState!.validate()) {
                if (_imagenEmpresa == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, selecciona una foto para la empresa')),
                  );
                  return;
                }
                
                // AQUÍ SÍ: Cerramos mandando los datos completos a la HomeScreen
                Navigator.pop(context, {
                  'tipo': 'empresa',
                  'nombre': _nombreEmpresaCtrl.text,
                  'imagenFile': _imagenEmpresa,
                });
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, TextInputType type) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: (val) => val == null || val.isEmpty ? 'Este campo es obligatorio' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF2E16D1)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBotonPublicar(VoidCallback accion) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: accion,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E16D1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text('PUBLICAR EN LA APP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ImagePicker {
  Future<XFile?> pickImage({required ImageSource source}) async {
    return null;
  }
}