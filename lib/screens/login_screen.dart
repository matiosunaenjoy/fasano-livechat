import 'package:flutter/material.dart';
import '../core/services/service_locator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _error('Ingresa tu email y contraseña');
      return;
    }

    setState(() => _loading = true);
    try {
      await services.authRepository.signInWithEmail(email, password);
    } catch (e) {
      _error(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A884).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business,
                      size: 40, color: Color(0xFF00A884)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Fasano Live Chat',
                  style: TextStyle(
                    color: Color(0xFFE9EDEF),
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comunicación interna',
                  style: TextStyle(color: Color(0xFF8696A0), fontSize: 14),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFFE9EDEF)),
                  decoration: const InputDecoration(
                    hintText: 'correo@empresa.com',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: Color(0xFF8696A0)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: const TextStyle(color: Color(0xFFE9EDEF)),
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF8696A0)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF8696A0),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Iniciar sesión',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Solo para empleados autorizados',
                  style: TextStyle(color: Color(0xFF8696A0), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
