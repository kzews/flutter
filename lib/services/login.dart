import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../environment.dart';
import '../objects/userDto.dart';

Future<UserDto> login(UserDto userDto) async {
  if (USE_FAKE_AUTH_API) {
    return UserDto(login: 'kirill99', role: 'admin', password: 'kirill99');
  }

  Dio dio = Dio();
//TODO: проверка доступности сервера
//   Проверка доступности сервера
  try {
    await dio.get('$API_URL/'); // Здесь можно использовать любой запрос к серверу
  } catch (e) {
    // Обработка ошибки - сервер не доступен
    print('Сервер не доступен: $e');
    throw Exception('Сервер не доступен');
  }

  // Если сервер доступен, отправляем запрос на аутентификацию
  try {
    var response = await dio.post(
      '$API_URL/api/login',
      data: jsonEncode(userDto),
      options: Options(
        contentType: "application/json",
        responseType: ResponseType.plain,
      ),
    );

    var userJson = jsonDecode(response.data);
    userDto.role = userJson['role'];
    userDto.id = userJson['id'];
    return UserDto.fromJson(jsonDecode(response.data));
  } on DioException catch (ex) {
    print(ex);
    throw ex;
  }
}
