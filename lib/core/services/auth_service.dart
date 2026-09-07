import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../constants/api_constants.dart';

part 'auth_service.g.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String baseUrl}) = _AuthService;

  @POST(ApiConstants.login)
  Future<HttpResponse<dynamic>> login(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.register)
  Future<HttpResponse<dynamic>> register(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.forgotPassword)
  Future<HttpResponse<dynamic>> forgotPassword(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.resetPassword)
  Future<HttpResponse<dynamic>> resetPassword(
    @Body() Map<String, dynamic> body,
  );

  @GET(ApiConstants.trainings)
  Future<HttpResponse<dynamic>> getTrainings();
}
