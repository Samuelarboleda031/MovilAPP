import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SideMenu extends StatelessWidget {
  final bool isClient;

  const SideMenu({super.key, this.isClient = false});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.content_cut,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 10),
                Text(
                  'Barbería',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pushReplacementNamed(
                  context, isClient ? '/client_home' : '/home');
            },
          ),
          if (!isClient) ...[
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Ventas'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/ventas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Agendamiento'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/agendamiento');
              },
            ),
          ],
          if (isClient) ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Mis Citas'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.pushReplacementNamed(context, '/cliente/mis-citas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Mis Compras'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.pushReplacementNamed(context, '/cliente/mis-compras');
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final auth = AuthService();
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }
}
