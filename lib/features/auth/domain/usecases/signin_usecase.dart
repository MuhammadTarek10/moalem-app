import 'package:injectable/injectable.dart';
import 'package:moalem/core/entities/tokens.dart';
import 'package:moalem/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<Tokens> call(String email, String password) {
    return _repository.signIn(email, password);
  }
}
