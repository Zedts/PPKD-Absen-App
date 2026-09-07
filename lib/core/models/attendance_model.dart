import 'package:json_annotation/json_annotation.dart';

part 'attendance_model.g.dart';

@JsonSerializable()
class AttendanceModel {
  final int? id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'attendance_date')
  final String? attendanceDate;
  @JsonKey(name: 'check_in_time')
  final String? checkInTime;
  @JsonKey(name: 'check_out_time')
  final String? checkOutTime;
  @JsonKey(name: 'check_in_lat', fromJson: _parseDouble)
  final double? checkInLat;
  @JsonKey(name: 'check_in_lng', fromJson: _parseDouble)
  final double? checkInLng;
  @JsonKey(name: 'check_out_lat', fromJson: _parseDouble)
  final double? checkOutLat;
  @JsonKey(name: 'check_out_lng', fromJson: _parseDouble)
  final double? checkOutLng;
  @JsonKey(name: 'check_in_address')
  final String? checkInAddress;
  @JsonKey(name: 'check_out_address')
  final String? checkOutAddress;
  @JsonKey(name: 'check_in_location')
  final String? checkInLocation;
  @JsonKey(name: 'check_out_location')
  final String? checkOutLocation;
  final String? status;
  @JsonKey(name: 'alasan_izin')
  final String? alasanIzin;

  const AttendanceModel({
    this.id,
    this.userId,
    this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInAddress,
    this.checkOutAddress,
    this.checkInLocation,
    this.checkOutLocation,
    this.status,
    this.alasanIzin,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);
}
