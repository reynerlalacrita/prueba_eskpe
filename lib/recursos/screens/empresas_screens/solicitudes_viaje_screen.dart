import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudesViajeScreen extends StatefulWidget {
  final String viajeId;
  final String nombreViaje;

  const SolicitudesViajeScreen({super.key, required this.viajeId, required this.nombreViaje});

  @override
  State<SolicitudesViajeScreen> createState() => _SolicitudesViajeScreenState();
}

class _SolicitudesViajeScreenState extends State<SolicitudesViajeScreen> {

  Future<void> _cambiarEstadoReserva(String reservaId, String nuevoEstado, int puestosReservados) async {
    try {
      if (nuevoEstado == 'Rechazada') {
        // Usar transacción para asegurar que los puestos regresen al viaje
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentReference reservaRef = FirebaseFirestore.instance.collection('reservaciones').doc(reservaId);
          DocumentReference viajeRef = FirebaseFirestore.instance.collection('viajes').doc(widget.viajeId);

          DocumentSnapshot viajeSnap = await transaction.get(viajeRef);
          if (viajeSnap.exists) {
            int disponiblesActuales = viajeSnap['puestosDisponibles'] ?? 0;
            transaction.update(viajeRef, {
              'puestosDisponibles': disponiblesActuales + puestosReservados,
            });
          }

          transaction.update(reservaRef, {'estado': nuevoEstado});
        });
      } else {
        // Si es Aceptada, solo actualizamos el estado
        await FirebaseFirestore.instance.collection('reservaciones').doc(reservaId).update({
          'estado': nuevoEstado
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reserva marcada como $nuevoEstado"), backgroundColor: nuevoEstado == 'Aceptada' ? Colors.green : Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarAccion(String reservaId, String accion, int puestosReservados) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¿$accion reserva?"),
        content: Text(accion == 'Aceptar' 
            ? "El usuario será notificado de que su reserva ha sido confirmada." 
            : "Los $puestosReservados puestos retenidos serán devueltos a los puestos disponibles de este viaje."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accion == 'Aceptar' ? Colors.green : Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _cambiarEstadoReserva(reservaId, accion == 'Aceptar' ? 'Aceptada' : 'Rechazada', puestosReservados);
            },
            child: Text(accion, style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("Solicitudes: ${widget.nombreViaje}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservaciones')
            .where('viajeId', isEqualTo: widget.viajeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2A4F)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No hay solicitudes para este viaje.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          final solicitudes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final data = solicitudes[index].data() as Map<String, dynamic>;
              return _buildTarjetaSolicitud(solicitudes[index].id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildTarjetaSolicitud(String reservaId, Map<String, dynamic> data) {
    String estado = data['estado'] ?? 'Pendiente';
    Color colorEstado = Colors.orange;
    
    if (estado == 'Aceptada') colorEstado = Colors.green;
    if (estado == 'Rechazada') colorEstado = Colors.red;

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['usuarioNombre'] ?? 'Usuario',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2A4F)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(estado, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const Divider(height: 25),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(data['usuarioContacto'] ?? 'Sin teléfono', style: const TextStyle(color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Puestos: ${data['puestosReservados'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Plan: ${data['planSeleccionado'] ?? 'Único'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F))),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Pago: \$${data['totalPago'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA53030))),
            ],
          ),
          const SizedBox(height: 5),
          Text("Solicitado el: $fechaStr", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          
          if (estado == 'Pendiente') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmarAccion(reservaId, "Rechazar", data['puestosReservados'] ?? 0),
                    child: const Text("Rechazar", style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmarAccion(reservaId, "Aceptar", data['puestosReservados'] ?? 0),
                    child: const Text("Aceptar", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
