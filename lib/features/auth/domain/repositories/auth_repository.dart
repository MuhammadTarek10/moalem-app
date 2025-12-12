import 'package:moalem/core/entities/tokens.dart';
import 'package:moalem/features/auth/data/models/signup_request.dart';

abstract class AuthRepository {
  Future<Tokens> signIn(String email, String password);
  Future<Tokens> signUp(SignupRequest request);
  Future<void> signOut();
}
