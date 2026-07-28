import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialReservasScreen extends StatelessWidget {
  const HistorialReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mis Reservas"), backgroundColor: const Color(0xFF1E2A4F)),
        body: const Center(child: Text("Debes iniciar sesión para ver tus reservas.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Mis Reservas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservaciones')
            .where('usuarioId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2A4F)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final reservas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final data = reservas[index].data() as Map<String, dynamic>;
              return _buildTarjetaReserva(context, reservas[index].id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            "No tienes reservas aún",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            "Explora nuestros destinos y anímate a viajar.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaReserva(BuildContext context, String reservaId, Map<String, dynamic> data) {
    String estado = data['estado'] ?? 'Pendiente';
    Color colorEstado = Colors.orange;
    IconData iconoEstado = Icons.pending_actions;

    if (estado == 'Aceptada') {
      colorEstado = Colors.green;
      iconoEstado = Icons.check_circle;
    } else if (estado == 'Rechazada') {
      colorEstado = Colors.red;
      iconoEstado = Icons.cancel;
    } else if (estado == 'Cancelada') {
      colorEstado = Colors.grey;
      iconoEstado = Icons.block;
    }

    // Formateo de fecha
    String fechaStr = '';
    if (data['fechaReservacion'] != null) {
      final dt = (data['fechaReservacion'] as Timestamp).toDate();
      fechaStr = "${dt.day}/${dt.month}/${dt.year}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['empresaNombre'] ?? 'Empresa',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2A4F)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(iconoEstado, size: 14, color: colorEstado),
                    const SizedBox(width: 5),
                    Text(
                      estado,
                      style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          _buildInfoRow(Icons.map, "Destino", data['destino'] ?? 'Desconocido'),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.group, "Puestos reservados", "${data['puestosReservados'] ?? 0}"),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.star, "Plan", data['planSeleccionado'] ?? 'Único'),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.payments, "Total a pagar", "\$${data['totalPago'] ?? 0}"),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.calendar_today, "Fecha de solicitud", fechaStr),
          if (estado == 'Pendiente' || estado == 'Aceptada') ...[
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmarCancelacion(context, reservaId, data),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                label: const Text("Cancelar Solicitud", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmarCancelacion(BuildContext context, String reservaId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Cancelar Reservación"),
        content: const Text("¿Estás seguro de que deseas cancelar esta reservación? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _cancelarReserva(context, reservaId, data);
            },
            child: const Text("Sí, cancelar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _cancelarReserva(BuildContext context, String reservaId, Map<String, dynamic> data) async {
    try {
      String viajeId = data['viajeId'];
      int puestosLiberados = data['puestosReservados'] ?? 0;

      DocumentReference viajeRef = FirebaseFirestore.instance.collection('viajes').doc(viajeId);
      DocumentReference reservaRef = FirebaseFirestore.instance.collection('reservaciones').doc(reservaId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot reservaSnap = await transaction.get(reservaRef);
        DocumentSnapshot viajeSnap = await transaction.get(viajeRef);

        if (!reservaSnap.exists || reservaSnap['estado'] == 'Cancelada' || reservaSnap['estado'] == 'Rechazada') {
          throw Exception("La reserva ya fue cancelada o rechazada.");
        }

        transaction.update(reservaRef, {'estado': 'Cancelada'});

        if (viajeSnap.exists) {
          int disponibles = viajeSnap['puestosDisponibles'] ?? 0;
          transaction.update(viajeRef, {'puestosDisponibles': disponibles + puestosLiberados});
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reservación cancelada con éxito"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cancelar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label:", style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
