import 'package:json_annotation/json_annotation.dart' show JsonSerializable;

part 'userDto.g.dart';

@JsonSerializable()
class UserDto {
  int? id;
  String? login;
  String? role;
  String? password;

  UserDto({
    required this.login,
    this.role,
    this.password,
    this.id,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
