import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/home/domain/usecases/fetch_and_store_user_usecase.dart';

final homeControllerProvider =
    StateNotifierProvider<HomeController, AsyncValue<bool>>((ref) {
      return HomeController(getIt<FetchAndStoreUserUseCase>());
    });

class HomeController extends StateNotifier<AsyncValue<bool>> {
  final FetchAndStoreUserUseCase _fetchAndStoreUserUseCase;

  HomeController(this._fetchAndStoreUserUseCase)
    : super(const AsyncValue.loading());

  Future<void> fetchAndStoreUser() async {
    state = const AsyncValue.loading();
    try {
      final isValid = await _fetchAndStoreUserUseCase();
      state = AsyncValue.data(isValid);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
