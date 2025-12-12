import 'package:moalem/core/entities/tokens.dart';
import 'package:moalem/features/auth/data/models/token_model.dart';

extension TokenMapper on TokenModel {
  Tokens toDomain() =>
      Tokens(accessToken: accessToken, refreshToken: refreshToken);
}
