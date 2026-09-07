import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../constants/api_constants.dart';

part 'profile_service.g.dart';

@RestApi()
abstract class ProfileService {
  factory ProfileService(Dio dio, {String baseUrl}) = _ProfileService;

  @GET(ApiConstants.profile)
  Future<HttpResponse<dynamic>> getProfile();

  @PUT(ApiConstants.profile)
  Future<HttpResponse<dynamic>> updateProfile(
    @Body() Map<String, dynamic> body,
  );

  @PUT('/api/profile/photo')
  Future<HttpResponse<dynamic>> updateProfilePhoto(
    @Body() Map<String, dynamic> body,
  );
}
