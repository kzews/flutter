import 'package:json_annotation/json_annotation.dart';

part 'userDto.g.dart';

@JsonSerializable()
class UserDto {
  String? login;

  String? password;



  UserDto({
    required this.login,

    this.password,


  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
