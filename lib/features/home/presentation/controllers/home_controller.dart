import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/home/domain/usecases/fetch_and_store_user_usecase.dart';

final homeControllerProvider =
    StateNotifierProvider<HomeController, AsyncValue<User?>>((ref) {
      return HomeController(getIt<FetchAndStoreUserUseCase>());
    });

class HomeController extends StateNotifier<AsyncValue<User?>> {
  final FetchAndStoreUserUseCase _fetchAndStoreUserUseCase;

  HomeController(this._fetchAndStoreUserUseCase)
    : super(const AsyncValue.loading());

  Future<void> fetchAndStoreUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _fetchAndStoreUserUseCase();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
