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

  bool get isIzin => (status ?? '').toLowerCase() == 'izin';

  bool get isTerlambat {
    if (isIzin) return false;
    if ((status ?? '').toLowerCase() == 'terlambat') return true;
    if (checkInTime != null && checkInTime!.isNotEmpty) {
      try {
        final timeOnly = checkInTime!.contains(' ')
            ? checkInTime!.split(' ').last
            : (checkInTime!.contains('T')
                ? checkInTime!.split('T').last
                : checkInTime!);
        final parts = timeOnly.split(':');
        if (parts.length >= 2) {
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          if (h > 8 || (h == 8 && m > 0)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  bool get isHadir {
    if (isIzin || isTerlambat) return false;
    return (status ?? '').toLowerCase() == 'masuk' ||
        (checkInTime != null && checkInTime!.isNotEmpty);
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    if (copy['check_in_time'] == null && copy['check_in'] != null) {
      copy['check_in_time'] = copy['check_in'];
    }
    if (copy['check_out_time'] == null && copy['check_out'] != null) {
      copy['check_out_time'] = copy['check_out'];
    }
    return _$AttendanceModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);
}
