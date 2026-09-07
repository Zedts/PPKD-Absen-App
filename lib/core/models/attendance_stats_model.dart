import 'package:json_annotation/json_annotation.dart';

part 'attendance_stats_model.g.dart';

@JsonSerializable()
class AttendanceStatsModel {
  @JsonKey(name: 'total_absen')
  final int totalAbsen;
  @JsonKey(name: 'total_masuk')
  final int totalMasuk;
  @JsonKey(name: 'total_izin')
  final int totalIzin;
  @JsonKey(name: 'sudah_absen_hari_ini')
  final bool sudahAbsenHariIni;

  const AttendanceStatsModel({
    this.totalAbsen = 0,
    this.totalMasuk = 0,
    this.totalIzin = 0,
    this.sudahAbsenHariIni = false,
  });

  factory AttendanceStatsModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceStatsModelToJson(this);
}
