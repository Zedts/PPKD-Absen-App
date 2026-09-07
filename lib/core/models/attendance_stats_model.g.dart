// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceStatsModel _$AttendanceStatsModelFromJson(
  Map<String, dynamic> json,
) => AttendanceStatsModel(
  totalAbsen: (json['total_absen'] as num?)?.toInt() ?? 0,
  totalMasuk: (json['total_masuk'] as num?)?.toInt() ?? 0,
  totalIzin: (json['total_izin'] as num?)?.toInt() ?? 0,
  sudahAbsenHariIni: json['sudah_absen_hari_ini'] as bool? ?? false,
);

Map<String, dynamic> _$AttendanceStatsModelToJson(
  AttendanceStatsModel instance,
) => <String, dynamic>{
  'total_absen': instance.totalAbsen,
  'total_masuk': instance.totalMasuk,
  'total_izin': instance.totalIzin,
  'sudah_absen_hari_ini': instance.sudahAbsenHariIni,
};
