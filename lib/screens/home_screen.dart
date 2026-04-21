import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/services/service_locator.dart';
import '../core/services/notification_service.dart';
import 'chats_screen.dart';
import 'channels_screen.dart';
import 'directory_screen.dart';
import 'profile_screen.dart';
import 'search/global_search_screen.dart';
import 'admin/admin_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() => setState(() => _index = _tab.index));
    services.authRepository.setStatus(UserStatus.online);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(),
          style: const TextStyle(
            color: Color(0xFFE9EDEF),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GlobalSearchScreen(currentUser: widget.currentUser),
              ),
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminScreen(currentUser: widget.currentUser),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _menuAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'status', child: Text('Cambiar estado')),
              const PopupMenuItem(
                  value: 'settings', child: Text('Configuración')),
              const PopupMenuItem(
                  value: 'logout', child: Text('Cerrar sesión')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFF00A884),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00A884),
          unselectedLabelColor: const Color(0xFF8696A0),
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 24)),
            Tab(icon: Icon(Icons.tag, size: 24)),
            Tab(icon: Icon(Icons.people_outline, size: 24)),
            Tab(icon: Icon(Icons.person_outline, size: 24)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          ChatsScreen(currentUser: widget.currentUser),
          ChannelsScreen(currentUser: widget.currentUser),
          DirectoryScreen(currentUser: widget.currentUser),
          ProfileScreen(currentUser: widget.currentUser),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF00A884),
              child: const Icon(Icons.chat, color: Colors.white),
            )
          : null,
    );
  }

  String _title() {
    switch (_index) {
      case 0:
        return 'Chats';
      case 1:
        return 'Canales';
      case 2:
        return 'Directorio';
      case 3:
        return 'Perfil';
      default:
        return 'Empresa Chat';
    }
  }

  void _menuAction(String v) {
    switch (v) {
      case 'status':
        _showStatusDialog();
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: const Color(0xFF1F2C34),
        title: const Text('Cambiar estado',
            style: TextStyle(color: Color(0xFFE9EDEF))),
        children: UserStatus.values.map((s) {
          return SimpleDialogOption(
            onPressed: () {
              services.authRepository.setStatus(s);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(s),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(_statusLabel(s),
                    style: const TextStyle(
                        color: Color(0xFFE9EDEF))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Color(0xFFE9EDEF))),
        content: const Text(
            '¿Estás seguro?',
            style: TextStyle(color: Color(0xFF8696A0))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8696A0))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationService.cleanup();
              services.authRepository.signOut();
            },
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Color(0xFFFF4444))),
          ),
        ],
      ),
    );
  }

  Color _statusColor(UserStatus s) {
    switch (s) {
      case UserStatus.online:
        return const Color(0xFF00A884);
      case UserStatus.away:
        return const Color(0xFFFFC107);
      case UserStatus.busy:
        return const Color(0xFFFF4444);
      case UserStatus.offline:
        return const Color(0xFF8696A0);
    }
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
}
