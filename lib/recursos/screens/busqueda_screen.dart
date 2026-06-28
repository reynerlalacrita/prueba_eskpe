import 'package:flutter/material.dart';
import 'package:prueba_eskpe/recursos/colores.dart';

class BusquedaScreen extends StatelessWidget {
  const BusquedaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC),
      appBar: AppBar(title: const Text("Buscar destinos"), backgroundColor: AppColors.azul1),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Escribe el nombre del lugar...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(child: Text("Aquí aparecerán tus resultados")),
            ),
          ],
        ),
      ),
    );
  }
}