import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import '../widgets/side_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    return Scaffold(
      drawer: const SideMenu(),
      appBar: AppBar(
        title: const Text('Home'),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Bienvenido${user != null ? ': ${user.email}' : ''}'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/ventas'),
            child: const Text('Ir a Ventas'),
          ),
        ]),
      ),
    );
  }
}
