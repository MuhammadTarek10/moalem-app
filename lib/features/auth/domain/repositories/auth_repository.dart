import '../../../../core/entities/user.dart';

abstract class AuthRepository {
  Future<User> signIn(String email, String password);
  Future<User> signUp(String name, String email, String password);
  Future<void> signOut();
}
