// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fluttersrc/screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Database App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          labelStyle: TextStyle(color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Зеленый цвет для кнопки
            elevation: 0, // Высота тени кнопки
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20.0), // Сделать кнопку круглой
            ),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // Зеленый цвет для AppBar
        ),
        scaffoldBackgroundColor:
            Colors.green.withOpacity(0.87), // Прозрачно-зеленый фон
      ),
      home: const LoginPage(),
    );
  }
}
