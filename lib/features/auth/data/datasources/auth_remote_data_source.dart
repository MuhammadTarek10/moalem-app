import 'package:injectable/injectable.dart';

import '../../../../core/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String name, String email, String password);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> signIn(String email, String password) async {
    // Mock delay
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'test@test.com' && password == 'password') {
      return const UserModel(
        id: '1',
        email: 'test@test.com',
        name: 'Test User',
      );
    } else {
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<UserModel> signUp(String name, String email, String password) async {
    // Mock delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate successful registration
    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
    );
  }
}
