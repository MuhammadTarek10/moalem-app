import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/entities/tokens.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/auth/domain/usecases/signin_usecase.dart';
import 'package:moalem/features/auth/domain/usecases/signout_usecase.dart';
import 'package:moalem/features/auth/domain/usecases/signup_usecase.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<Tokens?>>((ref) {
      return AuthController(
        getIt<SignInUseCase>(),
        getIt<SignUpUseCase>(),
        getIt<SignOutUseCase>(),
      );
    });

class AuthController extends StateNotifier<AsyncValue<Tokens?>> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;

  AuthController(this._signInUseCase, this._signUpUseCase, this._signOutUseCase)
    : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final tokens = await _signInUseCase(email, password);
      state = AsyncValue.data(tokens);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final tokens = await _signUpUseCase(name, email, password);
      state = AsyncValue.data(tokens);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _signOutUseCase();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
