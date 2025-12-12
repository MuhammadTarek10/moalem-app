import 'package:dio/dio.dart';
import 'package:moalem/features/auth/data/models/token_model.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: 'https://moalem-api.vercel.app/api/v1')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // * Auth
  @POST('/auth/sign-in')
  Future<TokenModel> signIn(@Body() Map<String, dynamic> body);

  @POST('/auth/sign-up')
  Future<TokenModel> signUp(@Body() Map<String, dynamic> body);

  // * User
  @GET('/users/profile')
  Future<UserModel> getUser();

  @PATCH('/users/profile')
  Future<UserModel> updateUser(@Body() UserModel user);

  @DELETE('/users/profile')
  Future<void> deleteUser();
}
