import '../models/user_model.dart';

abstract class UserDirectoryRepository {
  Stream<List<UserModel>> getAllEmployees();
  Future<List<UserModel>> searchEmployees(String query);
  Stream<List<UserModel>> getEmployeesByDepartment(String department);
  Stream<List<String>> getDepartments();
  Future<UserModel?> getUserById(String userId);
  Stream<List<UserModel>> getOnlineUsers();
}
