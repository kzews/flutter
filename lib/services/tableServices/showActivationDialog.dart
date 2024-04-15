import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../environment.dart';

Future<void> showActivationDialog(
    BuildContext context, Map<String, dynamic> item) async {
  String activationCode = '';

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        scrollable: true,
        // insetPadding: EdgeInsets.all(400),
        title: const Text('Введите код активации'),
        content: Column(
          children: [
            TextField(
              onChanged: (value) {
                activationCode = value;
              },
              decoration: const InputDecoration(
                labelText: 'Код установки',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              activateLicense(context, item['license_type'],
                  item['license_number'], activationCode);

              Navigator.of(context).pop();
            },
            child: const Text('Активировать'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
        ],
      );
    },
  );
}

Future<void> activateLicense(BuildContext context, int licenseType,
    int licenseNumber, String activationCode) async {
  final response = await http.post(
    Uri.parse('$API_URL/api/createCode'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'install_key': activationCode,
      // 'password': password,
      'license_type': licenseType.toString(),
      'license_number': licenseNumber.toString(),
    }),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = json.decode(response.body);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(400),
          title: const Text('Успешно активировано'),
          content: Text('Код подтверждения: ${responseData['install_code']}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  } else {
    if (kDebugMode) {
      print(response.statusCode);
    }
    if (response.statusCode == 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Ошибка'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
