import 'package:moalem/core/entities/tokens.dart';

abstract class AuthRepository {
  Future<Tokens> signIn(String email, String password);
  Future<Tokens> signUp(String name, String email, String password);
  Future<void> signOut();
}
