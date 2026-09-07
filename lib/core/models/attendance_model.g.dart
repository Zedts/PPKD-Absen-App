// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) =>
    AttendanceModel(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      attendanceDate: json['attendance_date'] as String?,
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
      checkInLat: AttendanceModel._parseDouble(json['check_in_lat']),
      checkInLng: AttendanceModel._parseDouble(json['check_in_lng']),
      checkOutLat: AttendanceModel._parseDouble(json['check_out_lat']),
      checkOutLng: AttendanceModel._parseDouble(json['check_out_lng']),
      checkInAddress: json['check_in_address'] as String?,
      checkOutAddress: json['check_out_address'] as String?,
      checkInLocation: json['check_in_location'] as String?,
      checkOutLocation: json['check_out_location'] as String?,
      status: json['status'] as String?,
      alasanIzin: json['alasan_izin'] as String?,
    );

Map<String, dynamic> _$AttendanceModelToJson(AttendanceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'attendance_date': instance.attendanceDate,
      'check_in_time': instance.checkInTime,
      'check_out_time': instance.checkOutTime,
      'check_in_lat': instance.checkInLat,
      'check_in_lng': instance.checkInLng,
      'check_out_lat': instance.checkOutLat,
      'check_out_lng': instance.checkOutLng,
      'check_in_address': instance.checkInAddress,
      'check_out_address': instance.checkOutAddress,
      'check_in_location': instance.checkInLocation,
      'check_out_location': instance.checkOutLocation,
      'status': instance.status,
      'alasan_izin': instance.alasanIzin,
    };
