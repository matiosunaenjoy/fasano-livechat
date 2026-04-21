import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/services/service_locator.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel currentUser;
  const ProfileScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final color =
        DeptColors.forDepartment(currentUser.department);

    return ListView(
      children: [
        const SizedBox(height: 24),
        // Avatar
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: color,
                child: Text(
                  currentUser.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: currentUser.statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF111B21),
                        width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Nombre
        Center(
          child: Text(
            currentUser.displayName,
            style: const TextStyle(
                color: Color(0xFFE9EDEF),
                fontSize: 22,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            currentUser.email,
            style: const TextStyle(
                color: Color(0xFF8696A0), fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),

        // Info
        _InfoTile(
          icon: Icons.work_outline,
          label: 'Cargo',
          value: currentUser.position,
        ),
        _InfoTile(
          icon: Icons.business,
          label: 'Departamento',
          value: currentUser.department,
        ),
        if (currentUser.phoneNumber.isNotEmpty)
          _InfoTile(
            icon: Icons.phone,
            label: 'Extensión',
            value: currentUser.phoneNumber,
          ),
        _InfoTile(
          icon: Icons.circle,
          label: 'Estado',
          value: _statusLabel(currentUser.status),
          valueColor: currentUser.statusColor,
        ),
        if (currentUser.statusMessage.isNotEmpty)
          _InfoTile(
            icon: Icons.message,
            label: 'Mensaje de estado',
            value: currentUser.statusMessage,
          ),

        const Divider(color: Color(0xFF2A3942), height: 32),

        // Acciones
        ListTile(
          leading: const Icon(Icons.edit,
              color: Color(0xFF8696A0)),
          title: const Text('Editar perfil',
              style: TextStyle(color: Color(0xFFE9EDEF))),
          trailing: const Icon(Icons.chevron_right,
              color: Color(0xFF8696A0)),
          onTap: () => _editProfile(context),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline,
              color: Color(0xFF8696A0)),
          title: const Text('Cambiar contraseña',
              style: TextStyle(color: Color(0xFFE9EDEF))),
          trailing: const Icon(Icons.chevron_right,
              color: Color(0xFF8696A0)),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined,
              color: Color(0xFF8696A0)),
          title: const Text('Notificaciones',
              style: TextStyle(color: Color(0xFFE9EDEF))),
          trailing: const Icon(Icons.chevron_right,
              color: Color(0xFF8696A0)),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info_outline,
              color: Color(0xFF8696A0)),
          title: const Text('Acerca de',
              style: TextStyle(color: Color(0xFFE9EDEF))),
          trailing: const Text('v1.0.0',
              style:
                  TextStyle(color: Color(0xFF8696A0), fontSize: 13)),
          onTap: () {},
        ),
      ],
    );
  }

  String _statusLabel(UserStatus s) {
    switch (s) {
      case UserStatus.online:
        return 'Disponible';
      case UserStatus.away:
        return 'Ausente';
      case UserStatus.busy:
        return 'Ocupado';
      case UserStatus.offline:
        return 'Desconectado';
    }
  }

  void _editProfile(BuildContext context) {
    final nameCtrl =
        TextEditingController(text: currentUser.displayName);
    final statusCtrl =
        TextEditingController(text: currentUser.statusMessage);
    final phoneCtrl =
        TextEditingController(text: currentUser.phoneNumber);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        title: const Text('Editar perfil',
            style: TextStyle(color: Color(0xFFE9EDEF))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style:
                    const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Nombre',
                    labelStyle:
                        TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: statusCtrl,
                style:
                    const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Mensaje de estado',
                    labelStyle:
                        TextStyle(color: Color(0xFF8696A0))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                style:
                    const TextStyle(color: Color(0xFFE9EDEF)),
                decoration: const InputDecoration(
                    labelText: 'Extensión',
                    labelStyle:
                        TextStyle(color: Color(0xFF8696A0))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8696A0))),
          ),
          ElevatedButton(
            onPressed: () async {
              await services.authRepository.updateProfile(
                displayName: nameCtrl.text.trim(),
                statusMessage: statusCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8696A0), size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF8696A0), fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: valueColor ?? const Color(0xFFE9EDEF),
                      fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
