import 'package:flutter/material.dart';

DateTime? currentBackPressTime;

bool backButton(context) {
  if (currentBackPressTime == null ||
      DateTime.now().difference(currentBackPressTime!) > Duration(seconds: 2)) {
    currentBackPressTime = DateTime.now();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Нажмите еще раз, чтобы выйти'),
      ),
    );
    return false;
  }
  return true;
}
