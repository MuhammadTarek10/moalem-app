import 'package:injectable/injectable.dart';
import 'package:moalem/core/entities/tokens.dart';
import 'package:moalem/features/auth/data/models/signup_request.dart';

import '../repositories/auth_repository.dart';

@injectable
class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<Tokens> call(SignupRequest request) {
    return _repository.signUp(request);
  }
}
