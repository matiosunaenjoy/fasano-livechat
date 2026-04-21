import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      final doc = await _db.collection('users').doc(fbUser.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  UserModel? get currentUser => null;

  @override
  Future<UserModel> signInWithEmail(
      String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Usuario no encontrado en el directorio');
    }

    final user = UserModel.fromFirestore(doc.data()!, uid);

    if (!user.isActive) {
      await _auth.signOut();
      throw Exception('Tu cuenta ha sido desactivada.');
    }

    await _db.collection('users').doc(uid).update({
      'status': UserStatus.online.name,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return user;
  }

  @override
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String displayName,
    required String department,
    required String position,
    UserRole role = UserRole.employee,
  }) async {
    final credential =
        await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final now = DateTime.now();

    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      department: department,
      position: position,
      role: role,
      status: UserStatus.offline,
      lastSeen: now,
      createdAt: now,
      isActive: true,
    );

    await _db.collection('users').doc(uid).set(user.toFirestore());
    return user;
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? statusMessage,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No autenticado');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (statusMessage != null) updates['statusMessage'] = statusMessage;

    await _db.collection('users').doc(uid).update(updates);
  }

  @override
  Future<void> setStatus(UserStatus status) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'status': status.name,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deactivateUser(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isActive': false,
      'status': UserStatus.offline.name,
    });
  }

  @override
  Future<void> activateUser(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isActive': true,
    });
  }

  @override
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'status': UserStatus.offline.name,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
  }
}
