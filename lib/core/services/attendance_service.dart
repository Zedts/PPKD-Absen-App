import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../constants/api_constants.dart';

part 'attendance_service.g.dart';

@RestApi()
abstract class AttendanceService {
  factory AttendanceService(Dio dio, {String baseUrl}) = _AttendanceService;

  @GET(ApiConstants.absenToday)
  Future<HttpResponse<dynamic>> getTodayAbsen(
    @Query('attendance_date') String attendanceDate,
  );

  @GET(ApiConstants.absenStats)
  Future<HttpResponse<dynamic>> getStats(
    @Query('start') String start,
    @Query('end') String end,
  );

  @POST(ApiConstants.checkIn)
  Future<HttpResponse<dynamic>> checkIn(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.checkOut)
  Future<HttpResponse<dynamic>> checkOut(
    @Body() Map<String, dynamic> body,
  );

  @GET(ApiConstants.absenHistory)
  Future<HttpResponse<dynamic>> getHistory({
    @Query('start') String? start,
    @Query('end') String? end,
  });

  @POST(ApiConstants.izin)
  Future<HttpResponse<dynamic>> submitIzin(
    @Body() Map<String, dynamic> body,
  );
}
