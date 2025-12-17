import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<User>>((ref) {
      return ProfileController(getIt<UserRepository>());
    });

class ProfileController extends StateNotifier<AsyncValue<User>> {
  final UserRepository _userRepository;

  ProfileController(this._userRepository) : super(const AsyncValue.loading()) {
    getUser();
  }

  Future<void> getUser() async {
    try {
      final user = await _userRepository.getUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
