import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, Cliente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user != null && user.email != null)
              Text(
                user.email!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar agendamiento para cliente
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente: Agendar Cita')),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Agendar Cita'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implementar historial de citas
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente: Mis Citas')),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Mis Citas'),
            ),
          ],
        ),
      ),
    );
  }
}
