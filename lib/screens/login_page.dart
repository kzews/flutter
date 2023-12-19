import 'package:flutter/material.dart';
import 'package:fluttersrc/screens/test_page.dart';
import 'package:page_transition/page_transition.dart';

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

//TODO сделать конпку "назад" не выходом из приложения
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                  // Используйте состояние для переключения видимости пароля
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
                    color: Colors.green,
                    child: InkWell(
                      splashColor: Colors.greenAccent,
                      child: const SizedBox(
                          width: 56,
                          height: 56,
                          child:
                              Icon(Icons.arrow_forward, color: Colors.white)),
                      onTap: () {
                        var _login = _loginController.text.trim();
                        var _password = _passwordController.text;
                        UserDto userDto = UserDto(
                          login: _login,
                          password: _password,
                        );
                        login(userDto).then(
                          (value) async {
                            print(value);
                            Navigator.of(context)
                                .pushReplacement(PageTransition(
                              type: PageTransitionType.fade,
                              child: Home1Page(userDto: userDto),
                              duration: const Duration(milliseconds: 1000),
                            ));
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.green.withOpacity(0.87),
        ),
      ),
    );
  }
}
