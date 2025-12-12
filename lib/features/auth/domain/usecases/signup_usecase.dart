import 'package:injectable/injectable.dart';
import 'package:moalem/core/entities/tokens.dart';

import '../repositories/auth_repository.dart';

@injectable
class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<Tokens> call(String name, String email, String password) {
    return _repository.signUp(name, email, password);
  }
}
