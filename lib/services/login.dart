import 'dart:async';
import 'dart:convert';
// import 'dart:html';

import 'package:dio/dio.dart' as Dio;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as Storage;

import '../environment.dart';
import '../objects/userDto.dart';

final storage = Storage.FlutterSecureStorage();

// Сохранение токена в localStorage
// void saveTokenWeb(String token) {
//   window.localStorage['token'] = token;
// }

// Получение токена из localStorage
// String? getTokenWeb() {
//   return window.localStorage['token'];
// }

// Сохранение токена в безопасном хранилище
void saveToken(String token) async {
  await new Storage.FlutterSecureStorage().write(key: 'token', value: token);
}

// Получение токена из безопасного хранилища
Future<String?> getToken() async {
  return await storage.read(key: 'token');
}

Future<UserDto> login(BuildContext context, UserDto userDto) async {
  if (USE_FAKE_AUTH_API) {
    return UserDto(
        login: 'kirill99', role: 'admin', password: 'kirill99', token: null);
  }

  Dio.Dio dio = Dio.Dio();
  try {
    await dio
        .get('$API_URL/'); // Здесь можно использовать любой запрос к серверу
  } catch (e) {
    // Обработка ошибки - сервер не доступен
    print('Сервер не доступен: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('Сервер недоступен'),
        duration: Duration(seconds: 2),
      ),
    );
    throw Exception('Сервер не доступен');
  }

  // Если сервер доступен, отправляем запрос на аутентификацию
  try {
    var response = await dio.post(
      '$API_URL/api/login',
      data: jsonEncode(userDto),
      options: Dio.Options(
        contentType: "application/json",
        responseType: Dio.ResponseType.plain,
      ),
    );

    var userJson = jsonDecode(response.data);
    userDto.role = userJson['role'];
    userDto.id = userJson['id'];
    userDto.token = userJson['token'];
    saveToken(userJson['token']);
    // saveTokenWeb(userJson['token']);
    //getToken();
    // getTokenWeb();
    String? token = await getToken();
    print('токен который getToken= $token');
    // print('токен есть : ' + getTokenWeb().toString());
    return UserDto.fromJson(jsonDecode(response.data));
  } on Dio.DioException catch (ex) {
    print(ex);
    throw ex;
  }
}
