// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userDto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
      login: json['login'] as String?,
      role: json['role'] as String?,
      password: json['password'] as String?,
      id: json['id'] as int?,
    );

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
      'id': instance.id,
      'login': instance.login,
      'role': instance.role,
      'password': instance.password,
    };
