import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../environment.dart';

Map<int, bool> checkBoxStates = {};

Future<void> sendSelectedItemsToServer(BuildContext context, List<int> selectedIds) async {
  try {
    // Send item ID to the server
    var response = await http.get(Uri.parse('$API_URL/api/send_selected_items?ids=${selectedIds.join(',')}'));

    // Check if request was successful
    if (response.statusCode == 200) {
      // Save the received file
      final directory = (await getApplicationDocumentsDirectory()).path;
      final file = io.File('$directory/downloaded_file.docx');
      await file.writeAsBytes(response.bodyBytes);

      // Open the downloaded file
      OpenFile.open(file.path);

      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(150),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          backgroundColor: Colors.grey,
          content: Text('Файл успешно загружен и открыт'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(150),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          backgroundColor: Colors.red,
          content: Text('Ошибка при загрузке файла'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  } catch (e) {
    // Show an error message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(150),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        backgroundColor: Colors.red,
        content: Text('Ошибка при загрузке файла'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}