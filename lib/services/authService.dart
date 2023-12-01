// import 'dart:async';
// import 'dart:convert';
//
// import 'package:dio/dio.dart';
// import 'package:thyroid_ui/api/objects/userDto.dart';
// import 'package:thyroid_ui/environment.dart';
//
// Future<UserDto> signin(UserDto userDto) async {
//   if (USE_FAKE_AUTH_API) {
//     return UserDto(login: 'kirill99', blocked: false, passwordExpired: false);
//   }
//   Dio dio = Dio();
//
//   try {
//     Response response = await dio.post(
//       '${AUTH_API_URL}/public/signin',
//       data: jsonEncode(userDto),
//       options: Options(
//         contentType: "application/json",
//         responseType: ResponseType.plain,
//       ),
//     );
//     return UserDto.fromJson(jsonDecode(response.data));
//   } on DioError catch (ex) {
//     print(ex);
//     throw ex;
//   }
// }
