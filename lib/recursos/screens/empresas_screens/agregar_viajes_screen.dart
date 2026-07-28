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

  final TextEditingController _puestosController = TextEditingController();
  final TextEditingController _detallesController = TextEditingController();

  String? _destinoIdSeleccionado;
  DateTime? _fechaSeleccionada;
  bool _subiendo = false;

  // Lista para almacenar los planes agregados
  List<Map<String, dynamic>> _planes = [];

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
    _puestosController.dispose();
    _detallesController.dispose();
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
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  void _mostrarDialogoAgregarPlan() {
    String nombrePlan = 'Básico';
    final List<String> opcionesPlanes = ['Básico', 'Premium', 'Premium+', 'Premium ++'];
    final TextEditingController precioPlanController = TextEditingController();
    final TextEditingController beneficioController = TextEditingController();
    List<String> beneficiosAgregados = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Agregar Plan"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: nombrePlan,
                      decoration: const InputDecoration(labelText: "Selecciona el Plan", prefixIcon: Icon(Icons.star)),
                      items: opcionesPlanes.map((plan) {
                        return DropdownMenuItem(value: plan, child: Text(plan));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => nombrePlan = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: precioPlanController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Precio del Plan", prefixIcon: Icon(Icons.attach_money)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: beneficioController,
                            decoration: const InputDecoration(labelText: "Agregar beneficio", prefixIcon: Icon(Icons.card_giftcard)),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setStateDialog(() {
                                  beneficiosAgregados.add(val.trim());
                                  beneficioController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF1E2A4F)),
                          onPressed: () {
                            if (beneficioController.text.trim().isNotEmpty) {
                              setStateDialog(() {
                                beneficiosAgregados.add(beneficioController.text.trim());
                                beneficioController.clear();
                              });
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: beneficiosAgregados.map((b) {
                        return Chip(
                          label: Text(b, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setStateDialog(() {
                              beneficiosAgregados.remove(b);
                            });
                          },
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2A4F)),
                  onPressed: () {
                    if (precioPlanController.text.isNotEmpty) {
                      setState(() {
                        _planes.add({
                          'nombre': nombrePlan,
                          'precio': double.tryParse(precioPlanController.text) ?? 0.0,
                          'beneficios': List<String>.from(beneficiosAgregados),
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Agregar", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
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

    if (_planes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes agregar al menos un plan para este viaje."),
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
        'empresa': _empresaNombre,
        'empresaId': _empresaUid,
        'puestosTotales': int.parse(_puestosController.text),
        'puestosDisponibles': int.parse(_puestosController.text),
        'fecha': Timestamp.fromDate(_fechaSeleccionada!),
        'detallesViaje': _detallesController.text,
        'planes': _planes, // Nuevo arreglo de planes
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

                    const SizedBox(height: 20),

                    // 2. Planes del Viaje
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Planes de Precios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          onPressed: _mostrarDialogoAgregarPlan,
                          icon: const Icon(Icons.add, color: Color(0xFF1E2A4F)),
                          label: const Text("Agregar Plan", style: TextStyle(color: Color(0xFF1E2A4F))),
                        ),
                      ],
                    ),
                    if (_planes.isEmpty)
                      const Text("No has agregado ningún plan. Debes agregar al menos uno.", style: TextStyle(color: Colors.red, fontSize: 12))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _planes.length,
                        itemBuilder: (context, index) {
                          final plan = _planes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(plan['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Precio: \$${plan['precio']}"),
                                  const SizedBox(height: 5),
                                  if (plan['beneficios'] is List)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: (plan['beneficios'] as List).map<Widget>((b) => Chip(
                                        label: Text(b.toString(), style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                      )).toList(),
                                    )
                                  else if (plan['beneficios'] is String)
                                    Text("Beneficios: ${plan['beneficios']}"),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _planes.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
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
                    const SizedBox(height: 20),

                    // 5. Detalles Adicionales
                    TextFormField(
                      controller: _detallesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Detalles del viaje (Opcional)",
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
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
