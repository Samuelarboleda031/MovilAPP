import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _emailConfirmCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailConfirmCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final emailConf = _emailConfirmCtrl.text.trim();
    final pass = _passCtrl.text;
    final passConf = _passConfirmCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _showMessage('Complete todos los campos');
      return;
    }
    if (email != emailConf) {
      _showMessage('Los correos no coinciden');
      return;
    }
    if (pass != passConf) {
      _showMessage('Las contraseñas no coinciden');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signUp(email, pass);
      await _auth.sendEmailVerification();
      _showMessage('Cuenta creada. Revise su correo para verificar la cuenta.');
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Error al registrar');
    } catch (e) {
      _showMessage('Error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleRegister() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Error en registro con Google');
    } catch (e) {
      _showMessage('Error inesperado con Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _emailConfirmCtrl, decoration: const InputDecoration(labelText: 'Confirmar correo'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _passConfirmCtrl, decoration: const InputDecoration(labelText: 'Confirmar contraseña'), obscureText: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrarse'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _googleRegister,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Registrarse con Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}