//todas las empresas de la aplicacion
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/screens/destino_detalle_screen.dart';

class ListaEmpresasScreen extends StatelessWidget {
  const ListaEmpresasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todas las Empresas"),
        backgroundColor: const Color(0xFF1E2A4F),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Quitamos el .limit(7) para traer todo
        stream: FirebaseFirestore.instance.collectionGroup('empresas').snapshots(),
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
              final String nombreSeguro = data['nombre'] ?? 'Sin nombre';
              final String rutaSegura = data['rutaAsset'] ?? 'assets/MorrocoyTours.jpg';
              
              return _buildTarjetaDestino(context, nombreSeguro, rutaSegura, docs[index].id);
            },
          );
        },
      ),
    );
  }
  Widget _buildTarjetaDestino(BuildContext context, String nombre, String ruta, String id) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => 
          DestinoDetalleScreen(nombre: nombre, rutaAsset: ruta, destinoId: id)));
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