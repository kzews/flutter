import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> changeUser(
    int? itemId, String login, String password) async {
  final response = await http.put(
    Uri.parse('http://192.168.202.199:5000/api/userChange/$itemId'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'login': login,
      'password': password,
    }),
  );
}

