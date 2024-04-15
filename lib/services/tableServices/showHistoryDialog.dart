import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../environment.dart';

Future<void> showHistoryDialog(BuildContext context, int itemId) async {
  // Получите историю изменений элемента с помощью API запроса
  final response =
      await http.get(Uri.parse('$API_URL/api/items/$itemId/history'));

  if (response.statusCode == 200) {
    List<dynamic> history = json.decode(response.body);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('История изменений элемента'),
          content: SizedBox(
            width: double.minPositive,
            height: 300,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic> change =
                    history[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text('Дата изменения: ${change['date_modified']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var entry in change.entries)
                        Text(_getFormattedFieldName(entry.key) +
                            ': ${entry.value}'),
                    ],
                  ),
                );
              },
            ),
          ),
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
    // Если запрос не удался, показываем сообщение об ошибке
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ошибка'),
          content: const Text('Не удалось получить историю изменений.'),
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
  }
}

String _getFormattedFieldName(String fieldName) {
  switch (fieldName) {
    case 'date_modified':
      return 'Дата изменения';
    case 'date_shipping':
      return 'Дата отгрузки';
    case 'UNNorUNP':
      return 'УНН/УНП';
    case 'name':
      return 'Владелец';
    case 'key':
      return 'Серийный номер';
    case 'dogovor':
      return 'Договор';
    // Добавьте другие кейсы для переименования других полей
    default:
      return fieldName; // Если имя поля не требует переименования, возвращаем его без изменений
  }
}
