import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../environment.dart';

Future<void> deleteItem(
    BuildContext context, int itemId, Function() refreshItems) async {
  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: const Text('Вы уверены, что хотите удалить запись?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pop(true); // Пользователь подтвердил удаление
            },
            child: const Text('Да'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Пользователь отменил удаление
            },
            child: const Text('Нет'),
          ),
        ],
      );
    },
  );

  if (confirmDelete) {
    final response = await http.delete(
      Uri.parse('$API_URL/api/items/$itemId'),
    );

    if (response.statusCode == 200) {
      // Вызываем функцию обратного вызова для обновления списка элементов
      refreshItems();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Элемент успешно удален'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Ошибка удаления'),
            content: const Text('Не удалось удалить элемент.'),
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
}
