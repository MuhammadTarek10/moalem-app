import 'package:injectable/injectable.dart';

import '../../../../core/entities/user.dart';
import '../repositories/auth_repository.dart';

@injectable
class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<User> call(String name, String email, String password) {
    return _repository.signUp(name, email, password);
  }
}
