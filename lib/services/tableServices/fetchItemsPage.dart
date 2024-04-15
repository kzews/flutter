import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../environment.dart';

int currentPage = 1;
int pageSize = 10;
List<Map<String, dynamic>> items = [];

Future<void> fetchItemsPage(
    BuildContext context, Function(List<Map<String, dynamic>>) callback) async {
  try {
    final response = await http.get(
        Uri.parse('$API_URL/api/fetchItems?page=$currentPage&size=$pageSize'));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      final List<Map<String, dynamic>> itemsList =
          List<Map<String, dynamic>>.from(responseData);
      callback(itemsList);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Загрузка не удалась'),
          duration: Duration(seconds: 2),
        ),
      );
      throw Exception('Failed to load items');
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('Произошла ошибка: $error'),
        duration: const Duration(seconds: 2),
      ),
    );
    throw Exception('Failed to load items: $error');
  }
}
