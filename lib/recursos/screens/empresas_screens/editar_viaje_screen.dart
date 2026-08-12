import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';

class EditarViajeScreen extends StatefulWidget {
  final String viajeId;
  final Map<String, dynamic> datosViaje;

  const EditarViajeScreen({
    super.key,
    required this.viajeId,
    required this.datosViaje,
  });

  @override
  State<EditarViajeScreen> createState() => _EditarViajeScreenState();
}

class _EditarViajeScreenState extends State<EditarViajeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _puestosController;
  late TextEditingController _detallesController;
  late TextEditingController _descripcionController;

  DateTime? _fechaSeleccionada;
  bool _guardando = false;

  late int _puestosTotalesOriginales;
  late int _puestosDisponiblesOriginales;

  List<Map<String, dynamic>> _planes = [];

  @override
  void initState() {
    super.initState();
    
    // Cargar planes existentes o migrar el precio antiguo
    if (widget.datosViaje['planes'] != null) {
      _planes = List<Map<String, dynamic>>.from(widget.datosViaje['planes']);
    } else {
      String precio = widget.datosViaje['precioPorPuesto']?.toString() ?? widget.datosViaje['precio']?.toString() ?? '0';
      _planes = [
        {
          'nombre': 'Plan Único',
          'precio': double.tryParse(precio) ?? 0.0,
          'descripcion': 'Servicios básicos incluidos',
          'beneficios': 'Beneficios por defecto'
        }
      ];
    }

    _puestosTotalesOriginales = widget.datosViaje['puestosTotales'] ?? 0;
    _puestosDisponiblesOriginales =
        widget.datosViaje['puestosDisponibles'] ?? 0;

    _puestosController = TextEditingController(
      text: _puestosTotalesOriginales.toString(),
    );
    _descripcionController = TextEditingController(
      text: widget.datosViaje['descripcion'] ?? widget.datosViaje['detallesViaje'] ?? '',
    );
    _detallesController = TextEditingController(
      text: widget.datosViaje['detallesViaje'] ?? '',
    );

    if (widget.datosViaje['fecha'] != null) {
      _fechaSeleccionada = (widget.datosViaje['fecha'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _puestosController.dispose();
    _detallesController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _seleccionarFecha() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _fechaSeleccionada ?? DateTime.now().add(const Duration(days: 1)),
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
    final TextEditingController descripcionPlanController = TextEditingController();
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
                    TextField(
                      controller: descripcionPlanController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Descripción del Plan / Servicios incluidos",
                        hintText: "Ej. Incluye pasaje ida y vuelta + hospedaje + desayuno",
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: beneficioController,
                            decoration: const InputDecoration(labelText: "Agregar beneficio individual", prefixIcon: Icon(Icons.card_giftcard)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.azuleskpe),
                  onPressed: () {
                    if (precioPlanController.text.isNotEmpty) {
                      setState(() {
                        _planes.add({
                          'nombre': nombrePlan,
                          'precio': double.tryParse(precioPlanController.text) ?? 0.0,
                          'descripcion': descripcionPlanController.text.trim(),
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

  void _guardarCambios() async {
    if (!_formKey.currentState!.validate() || _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos requeridos."),
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

    setState(() => _guardando = true);

    try {
      int nuevosTotales = int.parse(_puestosController.text);

      // Calcular nuevos disponibles
      int diferenciaTotales = nuevosTotales - _puestosTotalesOriginales;
      int nuevosDisponibles = _puestosDisponiblesOriginales + diferenciaTotales;

      if (nuevosDisponibles < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Los puestos totales no pueden ser menores a los ya reservados.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _guardando = false);
        return;
      }

      final String descrip = _descripcionController.text.trim().isNotEmpty
          ? _descripcionController.text.trim()
          : _detallesController.text.trim();

      await FirebaseFirestore.instance
          .collection('viajes')
          .doc(widget.viajeId)
          .update({
            'puestosTotales': nuevosTotales,
            'puestosDisponibles': nuevosDisponibles,
            'fecha': Timestamp.fromDate(_fechaSeleccionada!),
            'descripcion': descrip,
            'detallesViaje': descrip,
            'planes': _planes,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Viaje actualizado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volver
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Editar Viaje",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _guardando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Destino (No editable, solo informativo)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('destinos').doc(widget.datosViaje['destinoId']).get(),
                              builder: (context, snapshot) {
                                String nombreDestino = widget.datosViaje['destinoId'] ?? 'Desconocido';
                                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.exists) {
                                  nombreDestino = snapshot.data!['nombre'] ?? nombreDestino;
                                }
                                return Text(
                                  "Destino: $nombreDestino\n(El destino no se puede editar)",
                                  style: const TextStyle(color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Planes del Viaje
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
                                  Text("Precio: \$${plan['precio']}", style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2A4F))),
                                  if (plan['descripcion'] != null && plan['descripcion'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Incluye: ${plan['descripcion']}",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                  const SizedBox(height: 5),
                                  if (plan['beneficios'] is List && (plan['beneficios'] as List).isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: (plan['beneficios'] as List).map<Widget>((b) => Chip(
                                        label: Text(b.toString(), style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                      )).toList(),
                                    )
                                  else if (plan['beneficios'] is String && plan['beneficios'].toString().isNotEmpty)
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

                    // Cantidad de Puestos
                    TextFormField(
                      controller: _puestosController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Total de puestos disponibles",
                        prefixIcon: const Icon(
                          Icons.airline_seat_recline_normal,
                        ),
                        helperText:
                            "Cupos reservados actualmente: ${_puestosTotalesOriginales - _puestosDisponiblesOriginales}",
                      ),
                      validator: (v) =>
                          v!.isEmpty ? "Define la capacidad" : null,
                    ),
                    const SizedBox(height: 20),

                    // Selector de Fecha
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

                    // Descripción del Viaje / Destino (Detallada)
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Descripción del Viaje / Destino",
                        hintText: "Itinerario general, qué incluye la experiencia, puntos de salida, recomendaciones...",
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Ingresa una descripción del viaje" : null,
                    ),
                    const SizedBox(height: 20),

                    // Detalles Adicionales
                    TextFormField(
                      controller: _detallesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Notas o detalles adicionales (Opcional)",
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Botón de guardar
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azuleskpe,
                        ),
                        onPressed: _guardarCambios,
                        child: const Text(
                          "Guardar Cambios",
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
