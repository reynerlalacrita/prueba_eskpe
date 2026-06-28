import 'package:flutter/material.dart';

class DestinoDetalleScreen extends StatelessWidget {
  final String nombre;
  final String rutaAsset;

  const DestinoDetalleScreen({super.key, required this.nombre, required this.rutaAsset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: Center(
        child: Column(
          children: [
            Image.asset(rutaAsset),
            const SizedBox(height: 20),
            Text("Bienvenido a $nombre", style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}