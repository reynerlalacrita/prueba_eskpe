//todas las empresas de la aplicacion
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/screens/empresa_detalle_screen.dart';

class ListaEmpresasScreen extends StatelessWidget {
  const ListaEmpresasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todas las Empresas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').where('rol', isEqualTo: 'empresa').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay empresas disponibles"));
          }

          final docs = snapshot.data!.docs;

          // Usamos un GridView para que se vea más profesional que una lista simple
          // ... (mantiene tus importaciones y la clase hasta el itemBuilder)

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              // 🛠️ AQUÍ ESTÁ EL CAMBIO: Manejamos valores nulos antes de pasarlos a la función
              final String nombreSeguro = data['nombres'] ?? 'Sin nombre';
              final String rutaSegura = data['rutaAsset'] ?? 'assets/MorrocoyTours.jpg';
              

              
              // Línea 50 corregida:
            return _buildTarjetaDestino(
                context, 
                nombreSeguro, 
                rutaSegura, 
                docs[index].id, 
                data['telefono'] ?? '584263211350' // Aquí pasas el teléfono o un número por defecto
);
              
            },
          );
        },
      ),
    );
  }
  Widget _buildTarjetaDestino(BuildContext context, String nombre, String ruta, String id, String telefono) {
  return GestureDetector(
      // Ejemplo cuando navegas hacia la pantalla de detalle:
onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmpresaDetalleScreen(
            nombreEmpresa: nombre, // Usas el parámetro 'nombre' que ya recibes
            rutaAsset: ruta,       // Usas el parámetro 'ruta' que ya recibes
            telefonoEmpresa: telefono, // <--- Ahora ya lo tienes
            destinoId: id,         // <--- Ahora ya lo tienes
          ),
        ),
      );
    },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(ruta.isNotEmpty ? ruta : 'assets/CaracasTours.jpg', fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}