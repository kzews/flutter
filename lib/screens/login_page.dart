import 'dart:convert';

import 'package:dio/dio.dart' as Dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:fluttersrc/screens/test_page.dart';
import 'package:page_transition/page_transition.dart';

import '../environment.dart';
import '../objects/userDto.dart';
import '../services/backButton.dart';
import '../services/login.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Database App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Добавлено состояние для отображения пароля
  DateTime? currentBackPressTime;
  Future<String?> token3 = getToken();
  late String _apiUrl = API_URL;
  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    String? token = await getToken();
    if (token != null) {
      await verifyToken(token);
    }
  }

  Future<void> verifyToken(String token) async {
    Dio.Dio dio = Dio.Dio();
    // Если сервер доступен, отправляем запрос на аутентификацию
    try {
      var response = await dio.post(
        '$API_URL/verify_token',
        data: jsonEncode({'token': token}), // Передаем токен как часть данных
        options: Dio.Options(
          contentType: "application/json",
          responseType: Dio.ResponseType.plain,
        ),
      );

      if (response.statusCode == 200) {

        // Если токен верифицирован успешно, создаем объект userDto
        UserDto userDto = UserDto.fromJson(jsonDecode(response.data));
        bool shouldShowButtons = userDto.role != "user";
        // Инициируем переход на страницу Home1Page с передачей userDto
        shouldShowButtons ? Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Home1Page(userDto: userDto),
          ),
        ): Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TablePage(userDto: userDto),
          ),
        );
      } else {
        // Обработка других статусов ответа (например, когда токен просрочен или невалиден)
        // Возможно, здесь вы захотите отобразить сообщение об ошибке или выполнить другие действия
      }
    } on Dio.DioException catch (ex) {
      print(ex);
      throw ex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return backButton(context);
      },
      child: Theme(
        data: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.black,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Вход'),
            backgroundColor: Colors.black,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 1500
                  ? 600
                  : MediaQuery.of(context).size.width < 750
                  ? 20
                  : 300,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        labelText: 'Логин',
                      ),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blueAccent,
                        child: InkWell(
                          splashColor: Colors.greenAccent,
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.arrow_forward, color: Colors.white),
                          ),
                          onTap: () async {
                            var _login = _loginController.text.trim();
                            var _password = _passwordController.text;
                            UserDto userDto = UserDto(
                              login: _login,
                              password: _password,
                              token: await getToken().toString(),
                            );
                            login(context, userDto).then(
                                  (value) async {
                                    bool shouldShowButtons = userDto.role != "user";
                                shouldShowButtons ? Navigator.of(context).pushReplacement(
                                  PageTransition(
                                    type: PageTransitionType.fade,
                                    child: Home1Page(userDto: userDto),
                                    duration: const Duration(milliseconds: 1000),
                                  ),
                                ):Navigator.of(context).pushReplacement(
                                  PageTransition(
                                    type: PageTransitionType.fade,
                                    child: TablePage(userDto: userDto),
                                    duration: const Duration(milliseconds: 1000),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: kIsWeb
                      ? SizedBox(
                    width: 300,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _apiUrl = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'API_URL',
                        hintText: API_URL,
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.save),
                          onPressed: () {
                            // Сохранение нового значения API_URL
                            API_URL = _apiUrl;
                            // Сохранение нового значения API_URL в environment.dart
                          },
                        ),
                      ),
                    ),
                  )
                      : SizedBox(
                    width: 300,
                    child: Text(
                      _apiUrl,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white12.withOpacity(0.87),
        ),
      ),
    );
  }
}
