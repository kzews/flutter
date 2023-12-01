
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../environment.dart';
import '../objects/userDto.dart';



Future<UserDto> login(UserDto userDto) async {
  if (USE_FAKE_AUTH_API) {
    return UserDto(login: 'kirill99');
  }
  Dio dio = Dio();

  try {
    var response = await dio.post(
      'http://192.168.202.199:5000/api/login',
      data: jsonEncode(userDto),
      options: Options(
        contentType: "application/json",
        responseType: ResponseType.plain,
      ),
    );
    return UserDto.fromJson(jsonDecode(response.data));
  } on DioException catch (ex) {
    print(ex);
    throw ex;
  }
}


