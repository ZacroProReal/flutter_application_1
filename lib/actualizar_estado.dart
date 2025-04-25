import 'package:flutter/material.dart';

class ActualizarEstadoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Estado'),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Nombre del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Selecciona el estado'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                EstadoSelector(label: 'Disponible', color: Colors.green),
                EstadoSelector(label: 'No disponible', color: Colors.red),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Acción para actualizar estado
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[200],
              ),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class EstadoSelector extends StatelessWidget {
  final String label;
  final Color color;

  const EstadoSelector({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.circle, color: color),
        Text(label),
      ],
    );
  }
}
