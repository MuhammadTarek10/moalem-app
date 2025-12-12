import 'package:dio/dio.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: 'https://mock-api.com/v1/')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // * Auth
  @POST('/auth/sign-in')
  Future<UserModel> signIn(@Body() Map<String, dynamic> body);

  @POST('/auth/sign-up')
  Future<UserModel> signUp(@Body() Map<String, dynamic> body);

  // * User
  @GET('/profile')
  Future<UserModel> getUser();

  @PATCH('/profile')
  Future<UserModel> updateUser(@Body() UserModel user);

  @DELETE('/profile')
  Future<void> deleteUser();
}
