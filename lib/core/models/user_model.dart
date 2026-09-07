import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'jenis_kelamin')
  final String? jenisKelamin;
  @JsonKey(name: 'profile_photo')
  final String? profilePhoto;
  @JsonKey(name: 'batch_id')
  final int? batchId;
  @JsonKey(name: 'training_id')
  final int? trainingId;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.jenisKelamin,
    this.profilePhoto,
    this.batchId,
    this.trainingId,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? jenisKelamin,
    String? profilePhoto,
    bool clearProfilePhoto = false,
    int? batchId,
    int? trainingId,
    String? emailVerifiedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      profilePhoto: clearProfilePhoto ? null : (profilePhoto ?? this.profilePhoto),
      batchId: batchId ?? this.batchId,
      trainingId: trainingId ?? this.trainingId,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
