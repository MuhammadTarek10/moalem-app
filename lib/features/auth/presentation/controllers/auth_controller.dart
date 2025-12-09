import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/features/auth/domain/usecases/signin_usecase.dart';
import 'package:moalem/features/auth/domain/usecases/signup_usecase.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      return AuthController(getIt<SignInUseCase>(), getIt<SignUpUseCase>());
    });

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;

  AuthController(this._signInUseCase, this._signUpUseCase)
    : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _signInUseCase(email, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _signUpUseCase(name, email, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void logout() {
    state = const AsyncValue.data(null);
    // Also call logout usecase if exists
  }
}
