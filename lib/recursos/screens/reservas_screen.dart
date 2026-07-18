import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservarViajeScreen extends StatefulWidget {
  final String viajeId;
  final Map<String, dynamic> datosViaje;

  const ReservarViajeScreen({
    super.key, 
    required this.viajeId, 
    required this.datosViaje
  });

  @override
  State<ReservarViajeScreen> createState() => _ReservarViajeScreenState();
}

class _ReservarViajeScreenState extends State<ReservarViajeScreen> {
  int _puestosAReservar = 1;
  bool _procesando = false;
  Map<String, dynamic>? _planSeleccionado;
  List<Map<String, dynamic>> _planesDisponibles = [];

  @override
  void initState() {
    super.initState();
    // Extraer planes o crear uno por defecto
    if (widget.datosViaje['planes'] != null && (widget.datosViaje['planes'] as List).isNotEmpty) {
      _planesDisponibles = List<Map<String, dynamic>>.from(widget.datosViaje['planes']);
      _planSeleccionado = _planesDisponibles.first; // Por defecto selecciona el primero
    } else {
      String precio = widget.datosViaje['precioPorPuesto']?.toString() ?? widget.datosViaje['precio']?.toString() ?? '0';
      _planesDisponibles = [
        {
          'nombre': 'Plan Único',
          'precio': double.tryParse(precio) ?? 0.0,
          'beneficios': 'Beneficios por defecto'
        }
      ];
      _planSeleccionado = _planesDisponibles.first;
    }
  }

  void _confirmarReservacion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para reservar.")),
      );
      return;
    }

    setState(() => _procesando = true);

    // Referencias a los documentos en Firestore
    DocumentReference viajeRef = FirebaseFirestore.instance.collection('viajes').doc(widget.viajeId);
    DocumentReference reservaRef = FirebaseFirestore.instance.collection('reservaciones').doc();

    try {
      // 🛠️ USO DE TRANSACCIÓN PARA EVITAR OVERBOOKING
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot viajeSnapshot = await transaction.get(viajeRef);
        DocumentSnapshot usuarioSnapshot = await transaction.get(FirebaseFirestore.instance.collection('usuarios').doc(user.uid));

        Map<String, dynamic> viajeData = viajeSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic>? usuarioData = usuarioSnapshot.exists ? (usuarioSnapshot.data() as Map<String, dynamic>) : null;

        if (!viajeSnapshot.exists) {
          throw Exception("El viaje ya no está disponible.");
        }

        int puestosDisponibles = viajeData['puestosDisponibles'] ?? 0;
        double precio = (viajeData['precioPorPuesto'] ?? 0).toDouble();
        String empresa = viajeData['empresaNombre'] ?? 'Empresa';
        String empresaId = viajeData['empresaId'] ?? '';
        String destino = viajeData['destinoId'] ?? 'Destino';
        
        String usuarioNombre = usuarioData != null ? (usuarioData['nombres'] ?? 'Usuario') : 'Usuario';
        String usuarioContacto = usuarioData != null ? (usuarioData['telefono'] ?? '') : '';

        // Validar si quedan puestos suficientes
        if (puestosDisponibles < _puestosAReservar) {
          throw Exception("¡Lo sentimos! Solo quedan $puestosDisponibles puestos disponibles.");
        }

        // 1. Restar los puestos del viaje organizado
        transaction.update(viajeRef, {
          'puestosDisponibles': puestosDisponibles - _puestosAReservar,
        });

        // 2. Crear el ticket de reservación
        transaction.set(reservaRef, {
          'usuarioId': user.uid,
          'usuarioNombre': usuarioNombre,
          'usuarioContacto': usuarioContacto,
          'viajeId': widget.viajeId,
          'destino': destino,
          'empresaNombre': empresa,
          'empresaId': empresaId,
          'puestosReservados': _puestosAReservar,
          'planSeleccionado': _planSeleccionado?['nombre'] ?? 'Desconocido',
          'precioPlan': _planSeleccionado?['precio'] ?? 0.0,
          'totalPago': (_planSeleccionado?['precio'] ?? 0.0) * _puestosAReservar,
          'fechaReservacion': FieldValue.serverTimestamp(),
          'estado': 'Pendiente', // Puede ser Pendiente, Aceptada, Rechazada, Cancelada
        });
      });

      if (mounted) {
        _mostrarDialogoExito();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text("¡Reserva Solicitada!"),
          ],
        ),
        content: Text(
          "Has reservado $_puestosAReservar puesto(s) con ${widget.datosViaje['empresaNombre']}. Revisa tu Historial de Viajes para gestionar el pago.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2A4F)),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Regresa al detalle del destino
            },
            child: const Text("Entendido", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double precioIndividual = (widget.datosViaje['precioPorPuesto'] ?? 0).toDouble();
    int maxPuestos = widget.datosViaje['puestosDisponibles'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("Detalle de Reserva", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta informativa del viaje de la empresa
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.datosViaje['empresaNombre'] ?? 'Agencia de Viajes', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F))),
                  const Divider(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Puestos disponibles:", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text("$maxPuestos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: maxPuestos < 5 ? Colors.orange : Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Selector de Planes
            const Text("Selecciona tu Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _planesDisponibles.length,
              itemBuilder: (context, index) {
                final plan = _planesDisponibles[index];
                final bool isSelected = _planSeleccionado == plan;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _planSeleccionado = plan;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E2A4F).withOpacity(0.05) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1E2A4F) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<Map<String, dynamic>>(
                          value: plan,
                          groupValue: _planSeleccionado,
                          activeColor: const Color(0xFF1E2A4F),
                          onChanged: (Map<String, dynamic>? value) {
                            setState(() {
                              _planSeleccionado = value;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(plan['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  Text("\$${plan['precio']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA53030), fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              if (plan['beneficios'] is List)
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: (plan['beneficios'] as List).map<Widget>((b) => Chip(
                                    label: Text(b.toString(), style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  )).toList(),
                                )
                              else if (plan['beneficios'] is String)
                                Text(plan['beneficios'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),

            // Selector de asientos/puestos
            const Text("¿Cuántos puestos deseas reservar?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _puestosAReservar > 1 ? () => setState(() => _puestosAReservar--) : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 40, color: Color(0xFF1E2A4F)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text("$_puestosAReservar", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: _puestosAReservar < maxPuestos ? () => setState(() => _puestosAReservar++) : null,
                  icon: const Icon(Icons.add_circle_outline, size: 40, color: Color(0xFF1E2A4F)),
                ),
              ],
            ),
            const SizedBox(height: 35),

            // Caja de total de pago resumido
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1E2A4F), borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total a pagar:", style: TextStyle(color: Colors.white70, fontSize: 18)),
                  Text("\$${(_planSeleccionado?['precio'] ?? 0.0) * _puestosAReservar}", 
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Botón de confirmación de reserva
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _procesando ? null : _confirmarReservacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA53030), // Color llamativo para accionar la compra
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _procesando 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Solicitar Reservación", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}