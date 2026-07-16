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

        if (!viajeSnapshot.exists) {
          throw Exception("El viaje ya no está disponible.");
        }

        int puestosDisponibles = viajeSnapshot['puestosDisponibles'] ?? 0;
        double precio = (viajeSnapshot['precioPorPuesto'] ?? 0).toDouble();
        String empresa = viajeSnapshot['empresaNombre'] ?? 'Empresa';
        String destino = viajeSnapshot['destinoId'] ?? 'Destino';

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
          'viajeId': widget.viajeId,
          'destino': destino,
          'empresaNombre': empresa,
          'puestosReservados': _puestosAReservar,
          'totalPago': precio * _puestosAReservar,
          'fechaReservacion': FieldValue.serverTimestamp(),
          'estado': 'Pendiente', // Puede ser Pendiente, Confirmado, etc.
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
                      const Text("Precio por puesto:", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text("\$$precioIndividual", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFA53030))),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                  Text("\$${precioIndividual * _puestosAReservar}", 
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