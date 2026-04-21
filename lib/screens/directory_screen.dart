import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/services/service_locator.dart';
import '../theme.dart';
import 'chat_screen.dart';

class DirectoryScreen extends StatefulWidget {
  final UserModel currentUser;
  const DirectoryScreen({super.key, required this.currentUser});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: Color(0xFFE9EDEF)),
            decoration: const InputDecoration(
              hintText: 'Buscar empleado...',
              prefixIcon: Icon(Icons.search, color: Color(0xFF8696A0)),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: services.userDirectoryRepository.getAllEmployees(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00A884)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Color(0xFFFF4444)),
                  ),
                );
              }

              var employees = (snapshot.data ?? [])
                  .where((u) => u.uid != widget.currentUser.uid)
                  .toList();

              if (_query.isNotEmpty) {
                final q = _query.toLowerCase();
                employees = employees
                    .where((u) =>
                        u.displayName.toLowerCase().contains(q) ||
                        u.department.toLowerCase().contains(q) ||
                        u.position.toLowerCase().contains(q))
                    .toList();
              }

              if (employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No se encontraron empleados',
                          style: TextStyle(color: Color(0xFF8696A0))),
                      const SizedBox(height: 8),
                      Text(
                        'Total en snapshot: ${snapshot.data?.length ?? 0}',
                        style: const TextStyle(
                            color: Color(0xFF8696A0), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, i) {
                  final emp = employees[i];
                  final color = DeptColors.forDepartment(emp.department);

                  return ListTile(
                    onTap: () => _openChat(emp),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: color,
                          child: Text(
                            emp.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: emp.statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF111B21), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      emp.displayName,
                      style: const TextStyle(
                          color: Color(0xFFE9EDEF), fontSize: 15),
                    ),
                    subtitle: Text(
                      '${emp.position} · ${emp.department}',
                      style: const TextStyle(
                          color: Color(0xFF8696A0), fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF00A884), size: 20),
                      onPressed: () => _openChat(emp),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openChat(UserModel emp) async {
    final chat = await services.chatRepository.getOrCreateDirectChat(
      widget.currentUser.uid,
      emp,
    );
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chat: chat,
            currentUser: widget.currentUser,
          ),
        ),
      );
    }
  }
}
