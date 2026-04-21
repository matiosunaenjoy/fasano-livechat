import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/service_locator.dart';

class AdminScreen extends StatelessWidget {
  final UserModel currentUser;
  const AdminScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración',
            style: TextStyle(color: Color(0xFFE9EDEF))),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1F2C34),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings,
                    color: Color(0xFF00A884), size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panel de administración',
                          style: TextStyle(
                              color: Color(0xFFE9EDEF),
                              fontSize: 18,
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text('Gestiona usuarios y canales',
                          style: TextStyle(
                              color: Color(0xFF8696A0),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.person_add,
            'Crear empleado',
            'Agregar nuevo usuario',
            const Color(0xFF00A884),
            () => _createUserDialog(context),
          ),
          _tile(
            context,
            Icons.add_circle_outline,
            'Crear canal',
            'Nuevo canal departamental',
            const Color(0xFFF59E0B),
            () => _createChannelDialog(context),
          ),
          _tile(
            context,
            Icons.people_outline,
            'Gestionar empleados',
            'Ver y desactivar usuarios',
            const Color(0xFF3B82F6),
            () {},
          ),
          _tile(
            context,
            Icons.tag,
            'Gestionar canales',
            'Editar y eliminar canales',
            const Color(0xFF8B5CF6),
            () {},
          ),
          _tile(
            context,
            Icons.lock_reset,
            'Resetear contraseñas',
            'Enviar enlace de recuperación',
            const Color(0xFFEC4899),
            () {},
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, IconData icon, String title,
      String sub, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style:
              const TextStyle(color: Color(0xFFE9EDEF), fontSize: 15)),
      subtitle: Text(sub,
          style: const TextStyle(
              color: Color(0xFF8696A0), fontSize: 13)),
      trailing:
          const Icon(Icons.chevron_right, color: Color(0xFF8696A0)),
    );
  }

  void _createUserDialog(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    String dept = 'TI';

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        title: const Text('Crear empleado',
            style: TextStyle(color: Color(0xFFE9EDEF))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Email corporativo',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Contraseña temporal',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: posCtrl,
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Cargo',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: dept,
                dropdownColor: const Color(0xFF2A3942),
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Departamento',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
                items: [
                  'TI',
                  'Ventas',
                  'RRHH',
                  'Finanzas',
                  'Marketing',
                  'Operaciones',
                  'Gerencia'
                ]
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => dept = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8696A0))),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await services.authRepository.createUser(
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text,
                  displayName: nameCtrl.text.trim(),
                  department: dept,
                  position: posCtrl.text.trim(),
                );
                if (_.mounted) {
                  Navigator.pop(_);
                  ScaffoldMessenger.of(_).showSnackBar(
                    const SnackBar(
                        content: Text('Empleado creado'),
                        backgroundColor: Color(0xFF00A884)),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(_).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFFF4444)),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _createChannelDialog(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String dept = 'General';
    bool onlyAdmin = false;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1F2C34),
          title: const Text('Crear canal',
              style: TextStyle(color: Color(0xFFE9EDEF))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Nombre del canal',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: dept,
                dropdownColor: const Color(0xFF2A3942),
                style: const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Departamento',
                    labelStyle: TextStyle(color: Color(0xFF8696A0))),
                items: [
                  'General',
                  'TI',
                  'Ventas',
                  'RRHH',
                  'Finanzas',
                  'Marketing',
                  'Operaciones'
                ]
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setS(() => dept = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Solo admins pueden publicar',
                    style: TextStyle(
                        color: Color(0xFFE9EDEF), fontSize: 14)),
                value: onlyAdmin,
                activeColor: const Color(0xFF00A884),
                onChanged: (v) => setS(() => onlyAdmin = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF8696A0))),
            ),
            ElevatedButton(
              onPressed: () async {
                await services.chatRepository.createChannel(
                  name: nameCtrl.text.trim(),
                  createdBy: currentUser.uid,
                  department: dept,
                  description: descCtrl.text.trim(),
                  onlyAdminsCanPost: onlyAdmin,
                );
                if (_.mounted) Navigator.pop(_);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
