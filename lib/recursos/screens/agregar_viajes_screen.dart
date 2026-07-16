import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgregarViajeScreen extends StatefulWidget {
  const AgregarViajeScreen({super.key});

  @override
  State<AgregarViajeScreen> createState() => _AgregarViajeScreenState();
}

class _AgregarViajeScreenState extends State<AgregarViajeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar el texto
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _puestosController = TextEditingController();

  String? _destinoIdSeleccionado;
  DateTime? _fechaSeleccionada;
  bool _subiendo = false;

  // Variables para guardar los datos de la empresa actual
  String _empresaNombre = '';
  String _empresaUid = '';
  bool _cargandoDatosEmpresa = true;

  @override
  void initState() {
    super.initState();
    _obtenerDatosEmpresa();
  }

  @override
  void dispose() {
    _precioController.dispose();
    _puestosController.dispose();
    super.dispose();
  }

  // Función para jalar los datos de la empresa desde Firestore
  void _obtenerDatosEmpresa() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _empresaUid = user.uid;
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _empresaNombre = data['nombres'] ?? 'Mi Empresa';
            _cargandoDatosEmpresa = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error al obtener datos de empresa: $e");
    }
    setState(() {
      _cargandoDatosEmpresa = false;
    });
  }

  // Función para abrir el selector de fecha del teléfono
  void _seleccionarFecha() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)), // Mañana mínimo
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Hasta un año
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  void _guardarViaje() async {
    if (!_formKey.currentState!.validate() ||
        _destinoIdSeleccionado == null ||
        _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _subiendo = true);

    try {
      // Subimos el nuevo viaje organizado a Firestore
      await FirebaseFirestore.instance.collection('viajes').add({
        'destinoId': _destinoIdSeleccionado,
        'empresaNombre': _empresaNombre,
        'empresa': _empresaNombre, // para compatibilidad
        'empresaId': _empresaUid,
        'precioPorPuesto': double.parse(_precioController.text),
        'puestosTotales': int.parse(_puestosController.text),
        'puestosDisponibles': int.parse(
          _puestosController.text,
        ), // Al inicio, todos están libres
        'fecha': Timestamp.fromDate(
          _fechaSeleccionada!,
        ), // Formato nativo de Firebase para fechas
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Viaje publicado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volver al Perfil/Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Publicar Nuevo Viaje",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargandoDatosEmpresa || _subiendo
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 1. Destino (Cargado dinámicamente de tu colección 'destinos')
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('destinos')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }

                        var destinosDocs = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Selecciona el Destino",
                            prefixIcon: Icon(Icons.map),
                          ),
                          initialValue: _destinoIdSeleccionado,
                          items: destinosDocs.map((doc) {
                            String nombreDestino =
                                doc['nombre'] ?? 'Sin nombre';
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(nombreDestino),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _destinoIdSeleccionado = value),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // 2. Precio por Puesto
                    TextFormField(
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Precio por puesto",
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? "Coloca un precio válido" : null,
                    ),
                    const SizedBox(height: 20),

                    // 3. Cantidad de Puestos
                    TextFormField(
                      controller: _puestosController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Total de puestos disponibles",
                        prefixIcon: Icon(Icons.airline_seat_recline_normal),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? "Define la capacidad" : null,
                    ),
                    const SizedBox(height: 20),

                    // 4. Selector de Fecha
                    ListTile(
                      tileColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF1E2A4F),
                      ),
                      title: Text(
                        _fechaSeleccionada == null
                            ? "Seleccionar Fecha del Viaje"
                            : "Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}",
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _seleccionarFecha,
                    ),
                    const SizedBox(height: 40),

                    // Botón de publicación
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2A4F),
                        ),
                        onPressed: _guardarViaje,
                        child: const Text(
                          "Publicar Viaje",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
