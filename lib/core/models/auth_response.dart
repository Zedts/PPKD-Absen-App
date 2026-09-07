import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'auth_response.g.dart';

/// Wraps the auth endpoints' response: `{ token, user }`.
@JsonSerializable()
class AuthData {
  final String token;
  final UserModel user;

  const AuthData({required this.token, required this.user});

  factory AuthData.fromJson(Map<String, dynamic> json) =>
      _$AuthDataFromJson(json);

  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}

/// Generic API response wrapper: `{ message, data }`.
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final String message;
  final T? data;

  const ApiResponse({required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}
