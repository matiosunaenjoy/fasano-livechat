import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String displayName,
    required String department,
    required String position,
    UserRole role,
  });
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? statusMessage,
  });
  Future<void> setStatus(UserStatus status);
  Future<void> deactivateUser(String userId);
  Future<void> activateUser(String userId);
  Future<void> signOut();
}
