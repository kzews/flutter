import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../environment.dart';

Future<void> changeUser(
    int? itemId, String login, String password) async {
  final response = await http.put(
    Uri.parse('$API_URL/api/userChange/$itemId'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'login': login,
      'password': password,
    }),
  );
}

