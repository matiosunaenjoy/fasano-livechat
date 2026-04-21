import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/user_directory_repository.dart';

class FirebaseDirectoryRepository implements UserDirectoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<UserModel>> getAllEmployees() {
    return _db.collection('users').snapshots().map((snap) {
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final u = UserModel.fromFirestore(doc.data(), doc.id);
        if (u.isActive) users.add(u);
      }
      users.sort((a, b) => a.displayName.compareTo(b.displayName));
      return users;
    });
  }

  @override
  Future<List<UserModel>> searchEmployees(String query) async {
    final q = query.toLowerCase();
    final snap = await _db.collection('users').get();
    final results = <UserModel>[];
    for (final doc in snap.docs) {
      final u = UserModel.fromFirestore(doc.data(), doc.id);
      if (u.isActive &&
          (u.displayName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.department.toLowerCase().contains(q))) {
        results.add(u);
      }
    }
    return results;
  }

  @override
  Stream<List<UserModel>> getEmployeesByDepartment(String department) {
    return _db.collection('users').snapshots().map((snap) {
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final u = UserModel.fromFirestore(doc.data(), doc.id);
        if (u.isActive && u.department == department) {
          users.add(u);
        }
      }
      users.sort((a, b) => a.displayName.compareTo(b.displayName));
      return users;
    });
  }

  @override
  Stream<List<String>> getDepartments() {
    return _db.collection('users').snapshots().map((snap) {
      final depts = <String>{};
      for (final doc in snap.docs) {
        final d = doc.data()['department'] as String? ?? '';
        if (d.isNotEmpty) depts.add(d);
      }
      final list = depts.toList()..sort();
      return list;
    });
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Stream<List<UserModel>> getOnlineUsers() {
    return _db.collection('users').snapshots().map((snap) {
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final u = UserModel.fromFirestore(doc.data(), doc.id);
        if (u.isActive && u.status == UserStatus.online) {
          users.add(u);
        }
      }
      return users;
    });
  }
}
