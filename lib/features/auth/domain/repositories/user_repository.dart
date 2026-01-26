import 'package:moalem/core/entities/user.dart';

abstract class UserRepository {
  Future<User> getUser();
  Future<User> refreshUser();
  Future<void> updateUser(User user);
  Future<void> deleteUser();
}
